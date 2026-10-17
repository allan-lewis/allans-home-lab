{ config, lib, ... }:

let
  cfg = config.services.checkmk;
in
{
  options.services.checkmk = {
    enable = lib.mkEnableOption "Checkmk monitoring container" // {
      default = true;
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/checkmk";
      description = "Host directory for persistent Checkmk data.";
    };

    timeZone = lib.mkOption {
      type = lib.types.str;
      default = config.time.timeZone or null;
      defaultText = lib.literalExpression "config.time.timeZone";
      description = "Timezone used by the Checkmk container.";
    };

    passwordFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Path to an environment file containing CMK_PASSWORD.
        If null, Checkmk generates an initial password.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers.checkmk = {
      image = "docker.io/checkmk/check-mk-community:2.5.0@sha256:9eb222d05fe03d751f70ac7d8022cc655637679ba1d38922ee408e4e25058c26";

      autoStart = true;

      ports = [
        "8080:5000"
        "8000:8000"
      ];

      volumes = [
        "${cfg.dataDir}:/omd/sites"
      ];

      environment = {
        TZ = if cfg.timeZone == null then "UTC" else cfg.timeZone;
      };

      extraOptions = [
        "--cap-add=NET_RAW"
      ];

      environmentFiles =
        lib.optional (cfg.passwordFile != null) cfg.passwordFile;
    };
  };
}
