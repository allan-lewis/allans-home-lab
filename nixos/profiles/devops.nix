{ dopplerConfig, dopplerProject, dopplerTokenKey, ... }:
 
{
  imports = [
    ../modules/aws/lab.nix
    ../modules/devops.nix
    ../modules/lab-keys.nix
  ];
}