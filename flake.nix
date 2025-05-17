{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      treefmt-nix,
    }:
    let
      inherit (nixpkgs) lib;
      forEachSystem = lib.genAttrs lib.systems.flakeExposed;

      treefmtEval = forEachSystem (
        system: treefmt-nix.lib.evalModule (nixpkgs.legacyPackages.${system}) ./treefmt.nix
      );
    in
    {
      overlays.default = (
        final: prev: {
          mathb = final.callPackage ./mathb.nix { };
          mathb-live = final.callPackage ./mathb-live.nix { };
        }
      );

      packages = forEachSystem (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ self.overlays.default ];
          };
        in
        {
          inherit (pkgs) mathb mathb-live;
        }
      );

      nixosModules.default = import ./mod.nix;

      formatter = forEachSystem (system: treefmtEval.${system}.config.build.wrapper);
    };
}
