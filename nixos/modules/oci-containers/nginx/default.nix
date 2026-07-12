{
  services.homelab.containers.nginx = {
    image = "nginx:1.31.2@sha256:4ae259ae64fbedb67918c07d167fdcb0e05855a1615480ca445bea485e7d65ff";
    port = 80;
  };
}