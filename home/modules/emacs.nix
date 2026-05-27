# Emacs (headless) — turn on via settings.features.emacs.
# Ships emacs-nox plus the supporting tools an operator's emacs config usually
# needs: spell checkers (aspell + hunspell with Korean), mail (mu + isync +
# notmuch + afew), conversion (pandoc + imagemagick), grammar (languagetool),
# vterm dependencies, and a medium-sized TeX Live for org-mode export.
#
# Warning: first build is heavy. Set features.emacs = false on tiny VPS.
{ config, lib, pkgs, settings, ... }:

with lib;

{
  config = mkIf (settings.features.emacs or false) {
    programs.emacs = {
      enable        = true;
      package       = pkgs.emacs-nox;
      extraPackages = epkgs: [ epkgs.vterm ];
    };

    home.packages = with pkgs; [
      # Spell / grammar
      (aspellWithDicts (dicts: with dicts; [ en en-computers ]))
      ispell
      hunspell
      hunspellDicts.ko_KR
      languagetool

      # Mail
      mu
      isync
      notmuch
      afew

      # Org-mode helpers
      pandoc
      imagemagick
      libvterm

      # LaTeX (org-mode export). scheme-medium keeps the closure under control;
      # add packages explicitly when needed.
      (texlive.combine {
        inherit (texlive)
          scheme-medium
          dvisvgm
          dvipng
          wrapfig
          amsmath
          ulem
          hyperref
          capt-of
          parskip;
      })
    ];
  };
}
