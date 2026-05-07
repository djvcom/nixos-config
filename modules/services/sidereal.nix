{ inputs, ... }:

{
  flake.modules.nixos.sidereal =
    { config, pkgs, ... }:
    {
      imports = [ inputs.sidereal.nixosModules.sidereal ];

      systemd.services.sidereal.after = [ "kanidm.service" ];

      services.sidereal = {
        enable = true;
        package = inputs.sidereal.packages.${pkgs.stdenv.hostPlatform.system}.sidereal;

        grpcListenAddress = "127.0.0.1:4327";
        httpListenAddress = "127.0.0.1:4328";
        queryListenAddress = "127.0.0.1:3100";

        auth.oidc = {
          enable = true;
          issuer = "https://auth.djv.sh/oauth2/openid/sidereal";
          audience = "sidereal";
        };

        storage = {
          type = "s3";
          endpoint = "http://127.0.0.1:3900";
          bucket = "sidereal";
          region = "garage";
          forcePathStyle = true;
          allowHttp = true;
          credentialsFile = config.age.secrets.sidereal-s3-credentials.path;
        };
      };
    };
}
