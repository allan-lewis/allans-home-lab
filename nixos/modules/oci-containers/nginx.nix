{
  services.homelab.containers.nginx = {
    image = "nginx:1.29.8@sha256:a044d0fd8134074488707233ba76d924f152d5a2d97483812c950ef0656d7409";
    port = 80;
  };
}