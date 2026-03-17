{ ... }:

{
  users.users.lab.extraGroups = [ "aws" ];

  home-manager.users.lab = { ... }: {
    programs.git = {
      enable = true;
      settings = {
        user = {
          name = "Allan Lewis";
          email = "allan.e.lewis@gmail.com";
        };
      };
    };
  };
}