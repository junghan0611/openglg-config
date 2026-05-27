{
  description = "openglg-config home — reproducible operator shell on any Debian/Ubuntu";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      settings = import ./settings.nix;
      system   = settings.system or "aarch64-linux";
      pkgs     = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in {
      homeConfigurations.${settings.user.username} =
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            ./modules/minimal.nix
            ./modules/shell.nix
            ./modules/git.nix
            ./modules/cli.nix
            ./modules/tmux.nix
            ./modules/emacs.nix
            ./modules/gpg.nix
            ./modules/syncthing.nix
            ./modules/languages.nix
          ];
          extraSpecialArgs = { inherit settings; };
        };
    };
}
