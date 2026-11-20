{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    jdk25
    gradle_9
  ];
}
