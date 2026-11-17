{
  services.homelab.containers.nginx = {
    image = "docker.io/library/nginx:1.31.8@sha256:be17d9f8c2d0c2e4508fe75792d8d7cf52964904615b3557beceb2bfd8596b20";
    port = 80;
  };
}
