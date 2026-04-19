{
  description = "openglg-config home — Step 1 (minimal PoC)";

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
          modules = [ ./modules/minimal.nix ];
          extraSpecialArgs = { inherit settings; };
        };
    };
}
