{ config, pkgs, lib, nixosVersion, ... }:

let
  cfg = config.homelab.labUser;
in
{
  options.homelab.labUser = {
    enablePassword = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether the lab user should have a password set from SOPS.";
    };
  };

  config = {
    #: use zsh as the default shell
    programs.zsh.enable = true;

    #: create default/empty groups here
    users.groups.lab = {};
    users.groups.aws = {};

    #: setup lab user as a sudo user, optionally with a password
    users.mutableUsers = lib.mkIf cfg.enablePassword false;

    sops.secrets.lab_password = lib.mkIf cfg.enablePassword {
      sopsFile = ./passwords.yaml;
      neededForUsers = true;
    };

    users.users.lab = {
      isNormalUser = true;
      group = "lab";
      extraGroups = [ "wheel" ];
      shell = pkgs.zsh;

      hashedPassword =
        if cfg.enablePassword
        then null
        else "!";

      hashedPasswordFile =
        if cfg.enablePassword
        then config.sops.secrets.lab_password.path
        else null;
    };

    #: enable and configure home manager
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.backupFileExtension = "backup";

    #: home manager files/configs/programs
    home-manager.users.lab = { pkgs, ... }: {
      #: align with OS version from flake
      home.stateVersion = nixosVersion;

      #: zsh shell
      programs.zsh = {
        enable = true;
        autosuggestion.enable = true;
        syntaxHighlighting.enable = true;
        initContent = ''
          source ~/.config/zsh/zshrc.local
        '';
      };

      xdg.configFile."zsh/zshrc.local".source = ./dotfiles/zshrc.local;

      #: starship
      programs.starship = {
        enable = true;
      };

      xdg.configFile."starship.toml".source = ../../../dotfiles/starship/starship.toml;

      #: neovim
      xdg.configFile."nvim" = {
        source = ./dotfiles/nvim;
        recursive = true;
      };

      #: tmux
      programs.tmux = {
        enable = true;
        extraConfig = builtins.readFile ./dotfiles/tmux.conf;
      };

      #: packages
      home.packages = with pkgs; [
        fastfetch
        fd
        fzf
        neovim
        ripgrep
        starship
        tmux
      ];
    };
  };
}