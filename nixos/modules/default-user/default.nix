{ pkgs, lib, nixosVersion, ... }:

{
  #: use zsh as the default shell
  programs.zsh.enable = true;

  #: create default/empty groups here
  users.groups.lab = {};
  users.groups.aws = {};

  #: setup lab user as a sudo user with no password 
  users.users.lab = {
    isNormalUser = true;
    group = "lab";
    extraGroups = [ "wheel" ];
    shell = pkgs.zsh;
    hashedPassword = "!";
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
    xdg.configFile."starship.toml".source = ./dotfiles/starship.toml;

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
}