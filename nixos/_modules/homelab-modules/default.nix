{ ... }:

{

  imports = [
    ./hello.nix
    ./task-wrapper.nix
  ];

  #: enable the hello service by default
  services.homelab.hello = {
    enable = true;
  };

}
