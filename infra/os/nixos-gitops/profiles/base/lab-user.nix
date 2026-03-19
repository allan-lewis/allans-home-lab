{ pkgs, lib, ... }:

{
  programs.zsh.enable = true;

  users.groups.lab = {};
  users.groups.aws = {};

  users.users.lab = {
    isNormalUser = true;
    group = "lab";
    extraGroups = [ "wheel" ];
    shell = pkgs.zsh;
    hashedPassword = "!";
  };

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "backup";

  home-manager.users.lab = { pkgs, ... }: {
    home.stateVersion = "25.11";

    xdg.configFile."zsh/zshrc.local".source = ../../assets/zshrc.local;
    xdg.configFile."starship.toml".source = ../../assets/starship.toml;

    xdg.configFile."nvim" = {
      source = ../../assets/nvim;
      recursive = true;
    };

    programs.zsh = {
      enable = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      initContent = ''
        source ~/.config/zsh/zshrc.local
      '';
    };

    programs.starship = {
      enable = true;
    };

    programs.tmux = {
      enable = true;
      extraConfig = builtins.readFile ../../assets/tmux.conf;
    };

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

  environment.etc."tmux.conf".text = lib.mkForce "";
}