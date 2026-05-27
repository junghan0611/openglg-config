# GPG + pass — turn on via settings.features.gpg.
# Sets up gpg-agent with the curses pinentry (works over SSH), enables the
# password-store CLI with pass-otp, and — when settings.authInfoSource is
# non-empty — symlinks <home>/<authInfoSource> to ~/.authinfo.gpg on activation.
#
# Typical workflow: keep ~/.authinfo.gpg under a synced folder
# (e.g. settings.authInfoSource = "sync/org/authinfo.gpg") so every host the
# operator switches to gets the same encrypted auth bundle automatically.
{ config, lib, pkgs, settings, ... }:

with lib;

let
  authInfo = settings.authInfoSource or "";
in
{
  config = mkIf (settings.features.gpg or false) {
    programs.gpg.enable = true;

    services.gpg-agent = {
      enable                = true;
      pinentry.package      = pkgs.pinentry-curses;
      enableBashIntegration = true;
      defaultCacheTtl       = 31536000;
      maxCacheTtl           = 31536000;
      extraConfig = ''
        allow-emacs-pinentry
        allow-loopback-pinentry
      '';
    };

    programs.password-store = {
      enable  = true;
      package = pkgs.pass.withExtensions (exts: [ exts.pass-otp ]);
      settings = {
        PASSWORD_STORE_DIR = "${config.home.homeDirectory}/.password-store";
      };
    };

    home.packages = with pkgs; [ gnupg ];

    home.activation.createAuthInfoLink = mkIf (authInfo != "")
      (lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        AUTH_FILE="${config.home.homeDirectory}/${authInfo}"
        AUTH_LINK="${config.home.homeDirectory}/.authinfo.gpg"
        if [ -f "$AUTH_FILE" ]; then
          if [ -L "$AUTH_LINK" ] || [ ! -e "$AUTH_LINK" ]; then
            $DRY_RUN_CMD ln -sf "$AUTH_FILE" "$AUTH_LINK"
          fi
        fi
      '');
  };
}
