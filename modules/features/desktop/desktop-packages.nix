# Desktop system packages
_:

{
  flake.modules.nixos.desktop-packages =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        pavucontrol
        networkmanagerapplet
        playerctl
        wl-clipboard
        cliphist
        libnotify
        nautilus
        unzip
        p7zip
        htop
        pciutils
        usbutils
        lm_sensors
      ];
    };
}
