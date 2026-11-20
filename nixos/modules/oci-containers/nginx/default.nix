{
  services.homelab.containers.nginx = {
    image = "docker.io/library/nginx:1.31.9@sha256:31f2d286e83f45da0ebb1e33c894378c78b58a776e570572339019eb967e80ca";
    port = 80;
  };
}
