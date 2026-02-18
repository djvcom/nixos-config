_:

{
  flake.modules.nixos.security = {
    security = {
      sudo.extraRules = [
        {
          users = [ "dan" ];
          commands = [
            {
              command = "ALL";
              options = [ "NOPASSWD" ];
            }
          ];
        }
      ];
      protectKernelImage = true;
    };
  };
}
