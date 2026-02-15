{
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    ./hardware.nix
    # ./disko.nix  # Disabled - using existing partitions (Windows dual-boot)
    ./nvidia.nix
    ../../modules/base.nix
  ];

  networking = {
    hostName = "oshun";
    networkmanager.enable = true;
    firewall.enable = true;
  };

  nixpkgs.config.allowUnfree = true;

  # Desktop - Hyprland
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Login manager
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --cmd Hyprland";
        user = "greeter";
      };
    };
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
  };

  # Audio - PipeWire
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;
  };

  # Gaming
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = false;
    gamescopeSession.enable = true;
    extraCompatPackages = with pkgs; [
      proton-ge-custom
    ];
  };

  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };

  programs.gamemode = {
    enable = true;
    settings = {
      general.renice = 10;
      gpu = {
        apply_gpu_optimisations = "accept-responsibility";
        gpu_device = 0;
      };
    };
  };

  # Bluetooth (controllers)
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  services.blueman.enable = true;

  # User
  users.users.dan = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "audio"
      "input"
      "gamemode"
    ];
    shell = pkgs.bashInteractive;
  };

  environment.systemPackages = with pkgs; [
    # Gaming
    lutris
    heroic
    mangohud
    protonup-qt
    wine
    winetricks

    # Desktop
    pavucontrol
    networkmanagerapplet
    playerctl
    wl-clipboard
    cliphist
    libnotify

    # Files
    nautilus
    unzip
    p7zip

    # System
    htop
    pciutils
    usbutils
    lm_sensors
  ];

  fonts = {
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      jetbrains-mono
      font-awesome
      nerd-fonts.jetbrains-mono
    ];
    fontconfig.defaultFonts = {
      monospace = [ "JetBrains Mono" ];
      sansSerif = [ "Noto Sans" ];
      serif = [ "Noto Serif" ];
    };
  };

  nix.optimise = {
    automatic = true;
    dates = [ "weekly" ];
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    extraSpecialArgs = { inherit inputs; };
    users.dan =
      { ... }:
      {
        imports = [ ../../home/generic.nix ];
        _module.args.username = "dan";
      };
  };

  system.stateVersion = "25.11";
}
