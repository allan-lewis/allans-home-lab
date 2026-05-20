{ config, remoteBackupRoot, ... }:

{
  imports = [
    ../../modules/oci-containers/trilium
  ];

  sops.secrets."trilium/oauth_client_id" = {
    sopsFile = ./trilium.yaml;
  };

  sops.secrets."trilium/oauth_client_secret" = {
    sopsFile = ./trilium.yaml;
  };

  sops.templates."trilium.env".content = ''
    TRILIUM_MULTIFACTORAUTHENTICATION_OAUTHBASEURL=https://notes.allanshomelab.com
    TRILIUM_MULTIFACTORAUTHENTICATION_OAUTHCLIENTID=${config.sops.placeholder."trilium/oauth_client_id"}
    TRILIUM_MULTIFACTORAUTHENTICATION_OAUTHCLIENTSECRET=${config.sops.placeholder."trilium/oauth_client_secret"}
    TRILIUM_MULTIFACTORAUTHENTICATION_OAUTHISSUERBASEURL=https://authn.allanshomelab.com/application/o/trilium/
    TRILIUM_MULTIFACTORAUTHENTICATION_OAUTHISSUERNAME=Authentik
    TRILIUM_MULTIFACTORAUTHENTICATION_OAUTHISSUERICON=https://authn.allanshomelab.com/static/dist/assets/icons/icon.png
  '';

  services.homelab.trilium.environmentFile =
    config.sops.templates."trilium.env".path;

  homelab.managedDirectories.entries = {
    trilium = {
      local = "/var/lib/trilium";
      remote = "${remoteBackupRoot}/trilium";
      restore = true;
      backup = true;
      owner = "root";
      group = "root";
      mode = "0755";
    };
  };
}
