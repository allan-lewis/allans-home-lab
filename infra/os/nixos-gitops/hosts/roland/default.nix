{ config, pkgs, lib, ... }:

let
  cfg = config.homelab.bareMetal;
in
{
  imports = [
    ../../profiles/bare-metal
    ../../profiles/base
    ../../profiles/desktop
  ];

  networking.hostName = "roland";

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  time.timeZone = lib.mkForce "America/New_York";

  homelab.bareMetal = {
    interface = "enp4s0";
    address = "192.168.86.206";
    prefixLength = 24;
  };

  # ---- USER ----
  users.users.lab = {
    isNormalUser = true;
    extraGroups = [ "wheel" "video" "audio" ];
  };

  home-manager.users.lab = { ... }: {
    xdg.configFile."hypr/hyprland.conf".source =
      ../../assets/hypr/hyprland.conf;

    xdg.configFile."hypr/hypridle.conf".source =
      ../../assets/hypr/hypridle.conf;

    xdg.configFile."hypr/hyprlock.conf".source =
      ../../assets/hypr/hyprlock.conf;

    xdg.configFile."ghostty/config".source =
      ../../assets/ghostty/config.ghostty;

    home.file."wallpapers/default.png".source =
      ../../assets/wallpaper/nix-wallpaper-binary-blue.png;

    xdg.configFile."hypr/hyprpaper.conf".text = ''
      preload = /home/lab/wallpapers/default.png
      wallpaper = ,/home/lab/wallpapers/default.png
    '';

    xdg.userDirs = {
      enable = true;
      createDirectories = true;
    };

    home.packages = [
      pkgs.wlogout
    ];

    programs.waybar = {
      enable = true;

      settings = [
        {
          modules-left = [
            "custom/launcher"
            "custom/files"
            "custom/ghostty"
            "custom/browser"
          ];

          modules-right = [
            "cpu"
            "memory"
            "temperature"
            "network"
            "bluetooth"
            "pulseaudio"
            "clock"
            "custom/power"
          ];

          "custom/launcher" = {
            # format = "";
            format = "";
            tooltip = false;
            on-click = "wofi --show drun";
          };

          "custom/ghostty" = {
            # format = "";
            format = "󰆍";
            tooltip = false;
            on-click = "ghostty";
          };
        
          "custom/browser" = {
            format = "󰇧";
            tooltip = false;
            on-click = "google-chrome";
          };

          "custom/files" = {
            format = "󰉖";
            tooltip = false;
            on-click = "thunar";
          };

          "bluetooth" = {
            format = "Bt {status}";
            tooltip = false;
            on-click = "blueman-manager";
          };

          "pulseaudio" = {
            format = "Vol {volume}%";
            format-muted = "Muted";
            tooltip = false;
            on-click = "pactl set-sink-mute @DEFAULT_SINK@ toggle";
            on-click-right = "pavucontrol";
            scroll-step = 5;
          };

          "network" = {
            format-wifi = "{ipaddr}";
            format-ethernet = "{ipaddr}";
            format-disconnected = "Offline";
            interface = "enp4s0";
            tooltip = false;
          };

          "clock" = {
            format = "{:%H:%M | %a %b %d}";
            tooltip-format = "{:%Y-%m-%d %H:%M:%S}";
            tooltip = false;
          };

          "custom/power" = {
            format = "⏻";
            tooltip = false;
            on-click = "${pkgs.wlogout}/bin/wlogout -l /home/lab/.config/wlogout/layout -C /home/lab/.config/wlogout/style.css -b 4";
          };

          "cpu" = {
            format = "CPU {usage}%";
            tooltip = false;
          };

          "memory" = {
            format = "Mem {}%";
            tooltip = false;
          };

          "temperature" = {
            hwmon-path = "/sys/class/hwmon/hwmon0/temp1_input";
            critical-threshold = 80;
            format = "Temp {temperatureC}°C";
            format-critical = "TEMP {temperatureC}°C";
            tooltip = false;
          };
        }
      ];

      style = ''
        * {
          font-family: "JetBrainsMono Nerd Font", "JetBrains Mono Nerd Font", monospace;
          font-size: 14px;
        }

        #custom-power {
          margin-right: 8px;
        }

        #cpu,
        #memory,
        #temperature,
        #network,
        bluetooth,
        #pulseaudio,
        #clock {
          padding: 0 8px;
        }

        #custom-launcher {
          padding: 0 8px;
          margin-left: 8px;
        }

        #custom-browser,
        #custom-files,
        #custom-chrome {
          padding: 0 8px;
        }
      '';
    };

    xdg.configFile."wlogout/layout".text = ''
      {
        "label" : "lock",
        "action" : "hyprlock",
        "text" : "lock",
        "keybind" : "l"
      }
      {
        "label" : "logout",
        "action" : "hyprctl dispatch exit",
        "text" : "logout",
        "keybind" : "e"
      }
      {
        "label" : "reboot",
        "action" : "systemctl reboot",
        "text" : "reboot",
        "keybind" : "r"
      }
      {
        "label" : "shutdown",
        "action" : "systemctl poweroff",
        "text" : "shutdown",
        "keybind" : "s"
      }
    '';

xdg.configFile."wlogout/style.css".text = ''
  * {
    font-family: "JetBrainsMono Nerd Font", "JetBrains Mono Nerd Font", monospace;
    color: rgb(111, 141, 184);
  }

  window {
    background-color: rgba(20, 30, 50, 0.78);
    background-image: url("/home/lab/wallpapers/default.png");
    background-position: center;
    background-repeat: no-repeat;
    background-size: cover;
  }

  button {
    margin: 20px;
    padding: 24px;
    border-radius: 12px;
    border: 2px solid rgb(111, 141, 184);
    background: rgb(30, 45, 74);
    box-shadow: none;
    outline: none;
    min-width: 180px;
    min-height: 180px;
  }

  button:hover,
  button:focus,
  button:active {
    background: rgb(111, 141, 184);
    border-color: rgb(143, 168, 201);
    box-shadow: none;
    outline: none;
  }

  button label {
    font-family: "JetBrainsMono Nerd Font", "JetBrains Mono Nerd Font", monospace;
    font-size: 18px;
    font-weight: 500;
    color: rgb(111, 141, 184);
  }

  button:hover label,
  button:focus label,
  button:active label {
    color: rgb(30, 45, 74);
  }

  #lock,
  #logout,
  #reboot,
  #shutdown {
    background-position: center 32px;
    background-repeat: no-repeat;
    background-size: 64px;
    padding-top: 92px;
  }

  #lock {
    background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/lock.png"));
  }

  #logout {
    background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/logout.png"));
  }

  #reboot {
    background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/reboot.png"));
  }

  #shutdown {
    background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/shutdown.png"));
  }
'';
  };

  # ---- HYPRLAND ----
  programs.hyprland.enable = true;

  # Wayland + portals
  xdg.portal.enable = true;
  xdg.portal.extraPortals = [
    pkgs.xdg-desktop-portal-gtk
  ];

  # ---- GREETD LOGIN MANAGER ----
  systemd.defaultUnit = "graphical.target";

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --cmd Hyprland";
        user = "greeter";
      };
    };
  };

  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  # ---- AUDIO ----
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
  };

  security.rtkit.enable = true;

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  # ---- OPENSSH ----
  services.openssh.enable = true;

  services.homelab.managedState.enable = lib.mkForce false;

  system.stateVersion = "25.11";
}