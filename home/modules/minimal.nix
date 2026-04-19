{ config, lib, pkgs, settings, ... }:
{
  home.username      = settings.user.username;
  home.homeDirectory = "/home/${settings.user.username}";
  home.stateVersion  = settings.stateVersion;

  programs.home-manager.enable = true;

  programs.git = {
    enable    = true;
    userName  = settings.user.fullName;
    userEmail = settings.user.email;
  };

  programs.gh = {
    enable = true;
    settings.git_protocol = "https";
  };

  programs.bash = {
    enable           = true;
    enableCompletion = true;
  };

  # Smoke-test packages — enough to know the pipe works.
  home.packages = with pkgs; [
    ripgrep
    fd
    bat
  ];
}
