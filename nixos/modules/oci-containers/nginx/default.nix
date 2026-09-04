{
  services.homelab.containers.nginx = {
    image = "nginx:1.31.5@sha256:e10899b35d4e142d7408037f6e067afcc1ec3bb1eeb2a1c43d30a9450bab195d";
    port = 80;
  };
}