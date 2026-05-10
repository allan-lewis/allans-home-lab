{ config, lib, ... }:

let
  inherit (lib) mkOption types mkForce;

  cfg = config.homelab.gatus;

  gatusConfig = {
    metrics = true;

    storage = {
      type = "sqlite";
      path = "/var/lib/gatus/data.db";
    };

    endpoints = cfg.endpoints config.sops.placeholder;
  };
in
{
  options.homelab.gatus.endpoints = mkOption {
    type = types.functionTo (types.listOf types.attrs);
    default = _: [];
    description = "Function that returns Gatus endpoints given SOPS placeholders.";
  };

  config = {
    sops.templates."gatus.yaml" = {
      owner = "root";
      group = "root";
      mode = "0400";
      content = lib.generators.toYAML { } gatusConfig;
    };

    services.gatus = {
      enable = true;
      openFirewall = true;
      configFile = config.sops.templates."gatus.yaml".path;
    };

    systemd.services.gatus.serviceConfig = {
      DynamicUser = mkForce false;
      User = mkForce "root";
      Group = mkForce "root";
    };
  };
}