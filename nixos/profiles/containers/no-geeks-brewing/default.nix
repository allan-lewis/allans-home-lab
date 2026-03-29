{
  sops.secrets.homepage_env = {
    sopsFile = ../../../secrets/no-geeks-brewing.env;
    format = "dotenv";
    key = "";
  };

  services.homelab.containers.ngb = {
    image = "allanelewis/ngb-go@sha256:32261fc7b13d58ccb6bf8f43ea7e07bd60a9213598a05d0ea462fc223bb83ec2";
    port = 8080;
  };
}