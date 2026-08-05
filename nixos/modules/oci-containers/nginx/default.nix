{
  services.homelab.containers.nginx = {
    image = "nginx:1.31.3@sha256:b6be85cca2645765282b9bbb317ebc19d98dde48af447dd27a3b85841337766f";
    port = 80;
  };
}