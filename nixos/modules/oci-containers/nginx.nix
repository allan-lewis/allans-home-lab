{
  services.homelab.containers.nginx = {
    image = "nginx:1.30.0@sha256:1a9ab83e2892b75773978e8d91f42a7a2a0d8bb704959a51ff17c0377481973d";
    port = 80;
  };
}