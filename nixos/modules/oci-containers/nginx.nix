{
  services.homelab.containers.nginx = {
    image = "nginx:1.30.0@sha256:09b883524e0f17305310cd0c90e245b55d28b541a5202ddc0ecdafc51e38e395";
    port = 80;
  };
}