{
  description = "zig-tracy development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: let
    inherit (nixpkgs) lib;

    # flake-utils polyfill
    eachSystem = systems: fn:
      lib.foldl' (
        acc: system:
          lib.recursiveUpdate
          acc
          (lib.mapAttrs (_: value: {${system} = value;}) (fn system))
      ) {}
      systems;

    systems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
  in eachSystem systems (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = [
            pkgs.zig
            pkgs.zls
          ];
        };
      });
}

