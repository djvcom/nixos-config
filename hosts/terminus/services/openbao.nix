# OpenBao secrets management (HashiCorp Vault fork)
{ lib, ... }:

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

  # Systemd hardening for OpenBao
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
}
