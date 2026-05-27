# Language toolchains + LSPs — turn on via settings.features.languages.
# Heavy module: pulls in Node.js, Python 3.12 with a scientific stack,
# Go, Zig, Clojure, Nix language servers, C/C++ build tools, and shell
# tooling. Disable on small VPS unless you actually develop on the box.
{ config, lib, pkgs, settings, ... }:

with lib;

{
  config = mkIf (settings.features.languages or false) {
    home.packages = with pkgs; [
      # Node.js
      nodejs_22
      pnpm
      bun

      # Go
      go
      gopls

      # Zig
      zig
      zls

      # Clojure
      clojure
      clojure-lsp

      # Python (data-science friendly default)
      (python312.withPackages (ps: with ps; [
        ipdb
        ipykernel
        jupyter
        notebook
        jupyter-core
        jupyterlab
        pyzmq
        pandas
        tabulate
        flake8
      ]))
      black
      isort
      basedpyright

      # Nix dev
      nixd
      nil
      nixfmt-classic
      statix
      nix-init
      nix-update

      # Shell dev
      shfmt
      shellcheck
      bash-language-server

      # Security / pre-commit
      gitleaks

      # C / C++
      gcc
      gnumake
      clang-tools
      cmake
      libtool
      lldb

      # Build tools
      autoconf
      automake
      m4
      pkg-config
      openssl
    ];
  };
}
