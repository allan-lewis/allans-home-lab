{ ... }:

{
  imports = [
    ../../modules/gatus
  ];

  sops.secrets.tautulli_api_key = {
    sopsFile = ./gatus.yaml;
    key = "TAUTULLI_API_KEY";
  };

}
