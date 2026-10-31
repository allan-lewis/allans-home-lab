{
  services.homelab.containers.nginx = {
    image = "docker.io/library/nginx:1.31.8@sha256:e9063f3d18e2741f5a1e6f0deb475a36df1f88bb23d3123b85b0b1e485ee73ad";
    port = 80;
  };
}
