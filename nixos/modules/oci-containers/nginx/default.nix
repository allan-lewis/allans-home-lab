{
  services.homelab.containers.nginx = {
    image = "docker.io/library/nginx:1.31.10@sha256:9aa9949a8f50829ed3e3f5e14c95afd99caa00b0b5a5444ded23aca599458add";
    port = 80;
  };
}
