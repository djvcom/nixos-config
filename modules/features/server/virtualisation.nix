_:

{
  flake.modules.nixos.virtualisation = {
    virtualisation = {
      libvirtd = {
        enable = true;
        allowedBridges = [ "virbr0" ];
      };
      docker.enable = true;
    };
  };
}
