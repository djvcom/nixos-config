# Roundcube webmail for Stalwart
{ config, pkgs, ... }:

let
  desKeyPath = config.age.secrets.roundcube-des-key.path;
in
{
  services.roundcube = {
    enable = true;
    package = pkgs.roundcube.withPlugins (p: [ p.persistent_login ]);
    hostName = "localhost";

    database = {
      host = "localhost";
      dbname = "roundcube";
      username = "roundcube";
    };

    plugins = [ "persistent_login" ];

    extraConfig = ''
      $config['imap_host'] = 'ssl://mail.djv.sh:993';
      $config['smtp_host'] = 'tls://mail.djv.sh:587';
      $config['smtp_user'] = '%u';
      $config['smtp_pass'] = '%p';

      // Strip domain from username for IMAP/SMTP auth (Stalwart uses username, not email)
      // username_domain_forced replaces any domain in username with username_domain
      // Setting username_domain to empty effectively strips the domain
      ${"$"}config['username_domain'] = "";
      ${"$"}config['username_domain_forced'] = true;

      // Set mail domain for From address (not mail.djv.sh)
      $config['mail_domain'] = 'djv.sh';

      $config['product_name'] = 'djv.sh Webmail';
      $config['support_url'] = "";

      $config['des_key'] = file_get_contents('${desKeyPath}');

      $config['skin'] = 'elastic';
      $config['language'] = 'en_GB';
    '';
  };

  # nginx listens on localhost only; Traefik handles TLS termination
  services.nginx.virtualHosts."localhost" = {
    listen = [
      {
        addr = "127.0.0.1";
        port = 8083;
      }
    ];
    forceSSL = false;
    enableACME = false;
  };
}
