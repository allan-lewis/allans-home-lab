{
  services.homelab.containers.nginx = {
    image = "nginx:1.31.7@sha256:08da49e7dbe959c3082b2ec7086171946aa917c17db70ff7fe7add1687595688";
    port = 80;
  };
}