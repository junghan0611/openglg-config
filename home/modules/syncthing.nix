# Syncthing — turn on via settings.features.syncthing.
# Starts a per-user syncthing daemon bound to 127.0.0.1:8384. The first run
# creates a fresh, empty instance — pair it with your other devices and add
# folders through the web UI:
#
#   sudo loginctl enable-linger $USER         # survive logout
#   ssh -L 8384:localhost:8384 <this-host>    # tunnel UI
#   open http://localhost:8384                # accept HTTPS-cert prompt
#
# Use `stc` (from stc-cli) for a quick text status without the UI.
{ config, lib, pkgs, settings, ... }:

with lib;

{
  config = mkIf (settings.features.syncthing or false) {
    services.syncthing = {
      enable          = true;
      guiAddress      = "127.0.0.1:8384";
      overrideDevices = false;  # let the web UI manage devices
      overrideFolders = false;  # let the web UI manage folders
      settings = {
        options = {
          urAccepted    = -1;     # opt out of usage reporting
          relaysEnabled = true;
        };
      };
    };

    home.packages = with pkgs; [ stc-cli ];

    home.shellAliases = {
      # syncthing 2.0 moved its config under ~/.local/state/syncthing
      stc = "stc -homedir ~/.local/state/syncthing";
    };
  };
}
