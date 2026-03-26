{
  services.homelab.containers.it-tools = {
    image = "corentinth/it-tools@sha256:6f177c156b9466610e0f2093e24668b78da501c66f0054f98bccb582b74ab26b";
    port = 8386;
    internalPort = 80;
  };
}