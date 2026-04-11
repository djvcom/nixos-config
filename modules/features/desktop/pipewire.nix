_:

{
  flake.modules.nixos.pipewire =
    { pkgs, ... }:
    {
      services.pulseaudio.enable = false;
      services.pipewire = {
        enable = true;
        package = pkgs.pipewire.overrideAttrs (old: {
          mesonFlags = old.mesonFlags ++ [
            (pkgs.lib.mesonEnable "bluez5-codec-ldac-dec" false)
          ];
        });
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        jack.enable = true;
        wireplumber.enable = true;
      };
    };
}
