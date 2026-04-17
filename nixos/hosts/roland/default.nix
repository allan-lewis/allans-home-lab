{ backupRemotePrefix, config, pkgs, lib, ... }:


let
  cfg = config.homelab.bareMetal;
  
  inventoryConfig = builtins.fromTOML (builtins.readFile ../../../inventory/hosts/roland.toml);
  
  hostName = inventoryConfig.hostname;
  ipAddress = inventoryConfig.network.ipv4.address;

  defaultRemoteNasPerHostBackupVolume = "${backupRemotePrefix}/${hostName}";
in
{
  imports = [
    ../../profiles/bare-metal.nix
    ../../profiles/desktop.nix
  ];

  networking.hostName = hostName;

  homelab.bareMetal = {
    interface = "enp4s0";
    address = ipAddress;
  };

  time.timeZone = lib.mkForce "America/New_York";

  # home-manager.users.lab = { ... }: {
  #   programs.waybar = {
  #     enable = true;

  #     settings = [
  #       {
  #         modules-left = [
  #           "custom/power"
  #           "custom/identity"
  #           # "custom/launcher"
  #           # "custom/files"
  #           # "custom/ghostty"
  #           # "custom/browser"
  #         ];

  #         modules-center = [
  #           "clock"
  #           # "clock#center"
  #         ];

  #         modules-right = [
  #           "cpu"
  #           "memory"
  #           "temperature"
  #           "network"
  #           # "bluetooth"
  #           # "pulseaudio"
  #         ];

  #         "custom/launcher" = {
  #           # format = "";
  #           format = "";
  #           tooltip = false;
  #           on-click = "wofi --show drun";
  #         };

  #         "custom/ghostty" = {
  #           # format = "";
  #           format = "󰆍";
  #           tooltip = false;
  #           on-click = "ghostty";
  #         };
        
  #         "custom/browser" = {
  #           format = "󰇧";
  #           tooltip = false;
  #           on-click = "google-chrome-stable";
  #         };

  #         "custom/files" = {
  #           format = "󰉖";
  #           tooltip = false;
  #           on-click = "thunar";
  #         };

  #         "bluetooth" = {
  #           format = "Bt {status}";
  #           tooltip = false;
  #           on-click = "blueman-manager";
  #         };

  #         "pulseaudio" = {
  #           format = "Vol {volume}%";
  #           format-muted = "Muted";
  #           tooltip = false;
  #           on-click = "pactl set-sink-mute @DEFAULT_SINK@ toggle";
  #           on-click-right = "pavucontrol";
  #           scroll-step = 5;
  #         };

  #         "network" = {
  #           format-wifi = "{ipaddr}";
  #           format-ethernet = "{ipaddr}";
  #           format-disconnected = "Offline";
  #           interface = "enp4s0";
  #           tooltip = false;
  #         };

  #         "clock#center" = {
  #           format = "{:%H:%M | %A %B %d}";
  #           tooltip = false;
  #         };

  #         "custom/identity" = {
  #           exec = "echo \"$(whoami)@$(hostname)\"";
  #           interval = 60;
  #           tooltip = false;
  #         };

  #         "clock" = {
  #           format = "{:%H:%M | %a %b %d}";
  #           tooltip-format = "{:%Y-%m-%d %H:%M:%S}";
  #           tooltip = false;
  #         };

  #         "custom/power" = {
  #           format = "⏻";
  #           tooltip = false;
  #           on-click = "${pkgs.wlogout}/bin/wlogout -l /home/lab/.config/wlogout/layout -C /home/lab/.config/wlogout/style.css -b 4";
  #         };

  #         "cpu" = {
  #           format = "CPU {usage}%";
  #           tooltip = false;
  #         };

  #         "memory" = {
  #           format = "Mem {}%";
  #           tooltip = false;
  #         };

  #         "temperature" = {
  #           hwmon-path = "/sys/class/hwmon/hwmon0/temp1_input";
  #           critical-threshold = 80;
  #           format = "Temp {temperatureC}°C";
  #           format-critical = "TEMP {temperatureC}°C";
  #           tooltip = false;
  #         };
  #       }
  #     ];

  #     style = ''
  #       * {
  #         font-family: "JetBrainsMono Nerd Font", "JetBrains Mono Nerd Font", monospace;
  #         font-size: 14px;
  #         color: rgb(255, 255, 255);
  #         background-color: rgb(20, 30, 50);
  #       }

  #       #network {
        
  #       }

  #       #custom-identity {
  #         padding-left: 16px;
  #       }

  #       #clock {
  #       }

  #       #cpu,
  #       #memory,
  #       #temperature,
  #       #network {
  #         padding: 0 8px;
  #       }

  #       #custom-power {
  #         margin-left: 8px;
  #       }

  #       #custom-browser,
  #       #custom-files,
  #       #custom-ghostty {
  #         padding: 0 8px;
  #       }
  #     '';
  #   };

    # xdg.configFile."wlogout/layout".text = ''
    #   {
    #     "label" : "lock",
    #     "action" : "hyprlock",
    #     "text" : "lock",
    #     "keybind" : "l"
    #   }
    #   {
    #     "label" : "logout",
    #     "action" : "hyprctl dispatch exit",
    #     "text" : "logout",
    #     "keybind" : "e"
    #   }
    #   {
    #     "label" : "reboot",
    #     "action" : "systemctl reboot",
    #     "text" : "reboot",
    #     "keybind" : "r"
    #   }
    #   {
    #     "label" : "shutdown",
    #     "action" : "systemctl poweroff",
    #     "text" : "shutdown",
    #     "keybind" : "s"
    #   }
    # '';

# xdg.configFile."wlogout/style.css".text = ''
#   * {
#     font-family: "JetBrainsMono Nerd Font", "JetBrains Mono Nerd Font", monospace;
#     color: rgb(111, 141, 184);
#   }

#   window {
#     background-color: rgba(20, 30, 50, 0.78);
#     background-image: url("/home/lab/wallpapers/default.png");
#     background-position: center;
#     background-repeat: no-repeat;
#     background-size: cover;
#   }

#   button {
#     margin: 20px;
#     padding: 24px;
#     border-radius: 12px;
#     border: 2px solid rgb(111, 141, 184);
#     background: rgb(30, 45, 74);
#     box-shadow: none;
#     outline: none;
#     min-width: 180px;
#     min-height: 180px;
#   }

#   button:hover,
#   button:focus,
#   button:active {
#     background: rgb(111, 141, 184);
#     border-color: rgb(143, 168, 201);
#     box-shadow: none;
#     outline: none;
#   }

#   button label {
#     font-family: "JetBrainsMono Nerd Font", "JetBrains Mono Nerd Font", monospace;
#     font-size: 18px;
#     font-weight: 500;
#     color: rgb(111, 141, 184);
#   }

#   button:hover label,
#   button:focus label,
#   button:active label {
#     color: rgb(30, 45, 74);
#   }

#   #lock,
#   #logout,
#   #reboot,
#   #shutdown {
#     background-position: center 32px;
#     background-repeat: no-repeat;
#     background-size: 64px;
#     padding-top: 92px;
#   }

#   #lock {
#     background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/lock.png"));
#   }

#   #logout {
#     background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/logout.png"));
#   }

#   #reboot {
#     background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/reboot.png"));
#   }

#   #shutdown {
#     background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/shutdown.png"));
#   }
# '';
#   };

  system.stateVersion = "25.11";
}