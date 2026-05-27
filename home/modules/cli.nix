# Modern CLI — turn on via settings.features.cli.
# Adds neovim plus an "operator's drawer" of CLI tools: viewers, json/yaml,
# disk/process tools, networking, media, lazygit, etc. No identity-specific
# config — everything in here is a pure tool install.
{ config, lib, pkgs, settings, ... }:

with lib;

{
  config = mkIf (settings.features.cli or false) {
    programs.neovim = {
      enable        = true;
      viAlias       = true;
      vimAlias      = true;
      vimdiffAlias  = true;
      extraPackages = with pkgs; [ tree-sitter ];
    };

    home.packages = with pkgs; [
      # Viewers / inspectors
      htop btop
      eza tree
      ncdu duf procs psmisc
      lazygit tokei

      # Data
      jq yq-go miller htmlq

      # Utilities
      bc sqlite-interactive pv dos2unix socat
      mtr whois parallel fortune neofetch

      # Media
      sox yt-dlp ffmpeg

      # Network
      curl wget openssh nmap iproute2 iftop

      # Core GNU (consistent across distros)
      coreutils findutils gnugrep gnused gawk less which procps
    ];
  };
}
