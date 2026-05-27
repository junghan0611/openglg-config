# Extra git — turn on via settings.features.git.
# Adds aliases (co/ci/st/br/prettylog), LFS, delta as the diff viewer,
# and reasonable defaults (init.defaultBranch=main, pull.rebase=true,
# merge.conflictstyle=zdiff3).
#
# Identity (user.name/email) stays in modules/minimal.nix so it is set
# even with this feature off.
{ config, lib, pkgs, settings, ... }:

with lib;

{
  config = mkIf (settings.features.git or false) {
    programs.git = {
      lfs.enable = true;

      settings = {
        alias = {
          co        = "checkout";
          ci        = "commit";
          st        = "status";
          br        = "branch";
          hist      = "log --pretty=format:'%h %ad | %s%d [%an]' --graph --date=short";
          type      = "cat-file -t";
          dump      = "cat-file -p";
          prettylog = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(r) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative";
        };

        init.defaultBranch = "main";
        push.default       = "current";
        pull.rebase        = true;

        core = {
          editor            = "vim";
          filemode          = false;
          quotePath         = false;
          precomposeunicode = true;
          autocrlf          = "input";
        };

        diff = {
          tool          = "vimdiff";
          org.xfuncname = "^(\\*+ +.*|#\\+title:.*)$";
        };

        merge = {
          tool          = "vimdiff";
          conflictstyle = "zdiff3";
        };

        filter.lfs = {
          smudge   = "git-lfs smudge -- %f";
          process  = "git-lfs filter-process";
          required = true;
          clean    = "git-lfs clean -- %f";
        };

        color = {
          ui     = "auto";
          branch = "auto";
          diff   = "auto";
          status = "auto";
        };
      };
    };

    programs.delta = {
      enable = true;
      enableGitIntegration = true;
      options = {
        navigate     = true;
        line-numbers = true;
        syntax-theme = "Monokai Extended";
      };
    };
  };
}
