{
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    ./hardware.nix
    ./disko.nix
    ./nvidia.nix
    ../../modules/base.nix
  ];

  networking = {
    hostName = "oshun";
    networkmanager.enable = true;
    firewall.enable = true;
  };

  nixpkgs.config.allowUnfree = true;

  programs = {
    # Desktop - Hyprland
    hyprland = {
      enable = true;
      withUWSM = true;
      xwayland.enable = true;
    };

    # Gaming
    steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = false;
      gamescopeSession.enable = true;
      extraCompatPackages = with pkgs; [
        proton-ge-bin
      ];
    };

    gamescope = {
      enable = true;
      capSysNice = true;
    };

    gamemode = {
      enable = true;
      settings = {
        general.renice = 10;
        gpu = {
          apply_gpu_optimisations = "accept-responsibility";
          gpu_device = 0;
        };
      };
    };
  };

  services = {
    # Login manager
    greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd 'uwsm start hyprland-uwsm.desktop'";
          user = "greeter";
        };
      };
    };

    # Audio - PipeWire
    pulseaudio.enable = false;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
      wireplumber.enable = true;
    };

    # Bluetooth (controllers)
    blueman.enable = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
  };

  security.rtkit.enable = true;

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

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

  system = {
    autoUpgrade = {
      enable = true;
      allowReboot = true;
      dates = "07:00";
      flake = "github:djvcom/nixos-config#oshun";
      flags = [ "-L" ];
      rebootWindow = {
        lower = "07:00";
        upper = "08:00";
      };
      randomizedDelaySec = "5min";
    };

    stateVersion = "25.11";
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
}
