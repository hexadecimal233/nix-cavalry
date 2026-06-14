{
  description = "Cavalry motion graphics on Linux via Wine";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
  in {
    packages.${system}.default = pkgs.callPackage ./pkgs/cavalry.nix { };

    overlays.default = final: prev: {
      cavalry = final.callPackage ./pkgs/cavalry.nix { };
    };
  };
}
