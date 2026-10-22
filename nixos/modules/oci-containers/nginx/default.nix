{
  services.homelab.containers.nginx = {
    image = "nginx:1.31.8@sha256:d02f8188142c3e1940a530c4eb521b1a2cf7bb21ed4debeb131863e013ba9a3d";
    port = 80;
  };
}