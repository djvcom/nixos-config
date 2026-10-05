_:

{
  flake.modules.nixos.terminus = {
    age.secrets = {
      datadog-api-key = {
        file = ../../../secrets/datadog-api-key.age;
        owner = "root";
        group = "root";
        mode = "0400";
      };
      cloudflare-dns-token = {
        file = ../../../secrets/cloudflare-dns-token.age;
        owner = "acme";
        group = "traefik";
        mode = "0440";
      };
      git-identity = {
        file = ../../../secrets/git-identity.age;
        path = "/home/dan/.config/git/identity";
        owner = "dan";
        group = "users";
        mode = "0400";
      };
      kanidm-admin-password = {
        file = ../../../secrets/kanidm-admin-password.age;
        owner = "kanidm";
        group = "kanidm";
        mode = "0400";
      };
      kanidm-idm-admin-password = {
        file = ../../../secrets/kanidm-idm-admin-password.age;
        owner = "kanidm";
        group = "kanidm";
        mode = "0400";
      };
      kanidm-oauth2-vaultwarden = {
        file = ../../../secrets/kanidm-oauth2-vaultwarden.age;
        owner = "kanidm";
        group = "kanidm";
        mode = "0400";
      };
      garage-env = {
        file = ../../../secrets/garage-env.age;
        owner = "root";
        group = "root";
        mode = "0400";
      };
      vaultwarden-admin-token = {
        file = ../../../secrets/vaultwarden-admin-token.age;
        owner = "vaultwarden";
        group = "vaultwarden";
        mode = "0400";
      };
      vaultwarden-sso = {
        file = ../../../secrets/vaultwarden-sso.age;
        owner = "vaultwarden";
        group = "vaultwarden";
        mode = "0400";
      };
      backup-credentials = {
        file = ../../../secrets/backup-credentials.age;
        owner = "root";
        group = "root";
        mode = "0400";
      };
      sidereal-s3-credentials = {
        file = ../../../secrets/sidereal-s3-credentials.age;
        owner = "sidereal";
        group = "sidereal";
        mode = "0400";
      };
    };
  };
}
