{ pkgs }:

[
  {
    modules-left = [
      "custom/power"
      "custom/identity"
      # "custom/launcher"
      # "custom/files"
      # "custom/ghostty"
      # "custom/browser"
    ];

    modules-center = [
      "clock"
      # "clock#center"
    ];

    modules-right = [
      "cpu"
      "memory"
      "temperature"
      "network"
      # "bluetooth"
      # "pulseaudio"
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
      on-click = "google-chrome-stable";
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

    "clock#center" = {
      format = "{:%H:%M | %A %B %d}";
      tooltip = false;
    };

    "custom/identity" = {
      exec = "echo \"$(whoami)@$(hostname)\"";
      interval = 60;
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
]