_:

{
  flake.modules.nixos.jellyfin =
    { pkgs, ... }:
    {
      services.jellyfin = {
        enable = true;
        openFirewall = true;
      };

      hardware.nvidia-container-toolkit.enable = true;

      environment.systemPackages = with pkgs; [
        jellyfin-ffmpeg
      ];

      systemd.tmpfiles.rules = [
        "d /media/movies 0775 jellyfin users -"
        "d /media/tv 0775 jellyfin users -"
      ];

      users.users.jellyfin.extraGroups = [
        "render"
        "video"
      ];
    };
}
