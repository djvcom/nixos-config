{ lib, ... }:

{
  flake.modules.darwin.zscaler =
    { username, ... }:
    {
      security.pki.certificateFiles = [
        /Users/${username}/certs/zscaler.pem
      ];

      environment.variables = {
        NIX_SSL_CERT_FILE = lib.mkForce "/etc/ssl/certs/ca-certificates.crt";
        SSL_CERT_FILE = lib.mkForce "/etc/ssl/certs/ca-certificates.crt";
      };

      nix.settings.ssl-cert-file = "/etc/ssl/certs/ca-certificates.crt";
    };
}
