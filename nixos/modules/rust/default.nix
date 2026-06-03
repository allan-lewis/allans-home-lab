{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    rustc
    cargo
    rust-analyzer
    rustfmt
    clippy
    trunk
    lld
    wasm-bindgen-cli
  ];
}
