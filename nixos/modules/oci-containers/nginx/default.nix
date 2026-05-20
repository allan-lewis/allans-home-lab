{
  services.homelab.containers.nginx = {
    image = "nginx:1.31.0@sha256:eaa9f3dc265cd2ec0235e177d0a5fc7066c59ea6e57dd1ce22168e6a94c89922";
    port = 80;
  };
}