{
  services.homelab.containers.nginx = {
    image = "nginx:1.29.8@sha256:6e23479198b998e5e25921dff8455837c7636a67111a04a635cf1bb363d199dc";
    port = 80;
  };
}