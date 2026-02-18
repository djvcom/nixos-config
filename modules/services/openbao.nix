_:

{
  flake.modules.nixos.openbao =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      oidcSetupScript = pkgs.writeShellScript "openbao-oidc-setup" ''
        set -euo pipefail

        export BAO_ADDR="https://bao.djv.sh"

        # Check if we have a token
        if [ -z "''${BAO_TOKEN:-}" ]; then
          echo "Error: BAO_TOKEN environment variable not set"
          echo "Please set BAO_TOKEN to a root or admin token"
          exit 1
        fi

        # Wait for OpenBao to be ready
        echo "Waiting for OpenBao to be ready..."
        for i in $(seq 1 30); do
          if ${pkgs.openbao}/bin/bao status >/dev/null 2>&1; then
            break
          fi
          sleep 2
        done

        # Check if sealed
        if ${pkgs.openbao}/bin/bao status 2>&1 | grep -q "Sealed.*true"; then
          echo "Error: OpenBao is sealed. Please unseal first."
          exit 1
        fi

        # Check if OIDC auth is already enabled
        if ${pkgs.openbao}/bin/bao auth list 2>/dev/null | grep -q "^oidc/"; then
          echo "OIDC auth method already enabled, checking configuration..."
        else
          echo "Enabling OIDC auth method..."
          ${pkgs.openbao}/bin/bao auth enable oidc
        fi

        # Read OIDC client secret
        OIDC_CLIENT_SECRET=$(cat ${config.age.secrets.openbao-oidc-secret.path})

        # Configure OIDC
        echo "Configuring OIDC provider..."
        ${pkgs.openbao}/bin/bao write auth/oidc/config \
          oidc_discovery_url="https://auth.djv.sh/oauth2/openid/openbao" \
          oidc_client_id="openbao" \
          oidc_client_secret="$OIDC_CLIENT_SECRET" \
          default_role="default" \
          jwt_supported_algs=ES256

        # Configure default role
        echo "Configuring default OIDC role..."
        ${pkgs.openbao}/bin/bao write auth/oidc/role/default \
          user_claim="preferred_username" \
          allowed_redirect_uris="https://bao.djv.sh/ui/vault/auth/oidc/oidc/callback" \
          allowed_redirect_uris="https://bao.djv.sh/oidc/callback" \
          groups_claim="groups" \
          oidc_scopes="openid,profile,email,groups" \
          token_policies="default" \
          token_ttl="1h" \
          token_max_ttl="24h"

        # Create admin policy for openbao_admins group
        echo "Creating admin policy..."
        ${pkgs.openbao}/bin/bao policy write admin - <<'POLICY'
        # Full admin access
        path "*" {
          capabilities = ["create", "read", "update", "delete", "list", "sudo"]
        }
        POLICY

        # Map openbao_admins group to admin policy
        echo "Creating external group mapping..."

        # Get the OIDC auth accessor
        ACCESSOR=$(${pkgs.openbao}/bin/bao auth list -format=json | ${pkgs.jq}/bin/jq -r '.["oidc/"].accessor')

        # Check if group already exists
        if ${pkgs.openbao}/bin/bao read identity/group/name/openbao_admins >/dev/null 2>&1; then
          echo "Group openbao_admins already exists"
        else
          echo "Creating external group openbao_admins..."
          ${pkgs.openbao}/bin/bao write identity/group \
            name="openbao_admins" \
            type="external" \
            policies="admin"

          # Create group alias to map OIDC group
          GROUP_ID=$(${pkgs.openbao}/bin/bao read -format=json identity/group/name/openbao_admins | ${pkgs.jq}/bin/jq -r '.data.id')
          ${pkgs.openbao}/bin/bao write identity/group-alias \
            name="openbao_admins" \
            mount_accessor="$ACCESSOR" \
            canonical_id="$GROUP_ID"
        fi

        echo "OIDC configuration complete!"
        echo "You can now log in at https://bao.djv.sh/ui using OIDC"
      '';
    in
    {
      services.openbao = {
        enable = true;
        settings = {
          ui = true;
          api_addr = "https://bao.djv.sh";
          cluster_addr = "http://127.0.0.1:8201";

          # Listen on localhost only, Traefik handles TLS
          listener.tcp = {
            type = "tcp";
            address = "127.0.0.1:8200";
            tls_disable = true;
          };

          # Raft storage for single-node deployment
          storage.raft = {
            path = "/var/lib/openbao";
            node_id = "terminus";
          };
        };
      };

      systemd.services.openbao.serviceConfig = {
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        LockPersonality = true;
        CapabilityBoundingSet = lib.mkForce "";
        SystemCallFilter = [
          "@system-service"
          "~@privileged"
        ];
        SystemCallArchitectures = "native";
        ReadWritePaths = [ "/var/lib/openbao" ];
      };

      # OIDC setup service - run manually with: sudo systemctl start openbao-oidc-setup
      # Requires BAO_TOKEN to be set (via EnvironmentFile or manually)
      systemd.services.openbao-oidc-setup = {
        description = "Configure OpenBao OIDC authentication";
        after = [ "openbao.service" ];
        requires = [ "openbao.service" ];

        # Don't start automatically - this is a manual setup step
        wantedBy = [ ];

        serviceConfig = {
          Type = "oneshot";
          ExecStart = oidcSetupScript;
          EnvironmentFile = [
            # Contains BAO_TOKEN=<root-token>
            config.age.secrets.openbao-oidc-env.path
          ];

          NoNewPrivileges = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          PrivateTmp = true;
        };
      };
    };
}
