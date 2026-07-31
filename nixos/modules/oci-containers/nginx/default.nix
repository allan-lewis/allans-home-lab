{
  services.homelab.containers.nginx = {
    image = "nginx:1.31.3@sha256:db64e7488ecf69ffa4311e5febe889b15489c94e532d1e2b4be9d13e0d4428c6";
    port = 80;
  };
}