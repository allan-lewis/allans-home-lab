{
  services.homelab.containers.nginx = {
    image = "nginx:1.31.0@sha256:772053fe58eaa882734db7ad8d2327e982374ab3d17f302453cd850d975aba38";
    port = 80;
  };
}