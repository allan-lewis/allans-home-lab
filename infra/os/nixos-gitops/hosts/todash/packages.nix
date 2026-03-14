{ pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    awscli2
    btop
    clang
    cmatrix
    curl
    doppler
    gcc
    ghostty.terminfo
    git
    gnumake
    jq
    just
    net-tools
    python3
    trash-cli
    tree
    tree-sitter
    unzip
  ];

}