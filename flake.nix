{
  description = "zig-glfw development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    zig-overlay.url = "github:mitchellh/zig-overlay";
    zig-overlay.inputs.nixpkgs.follows = "nixpkgs";

    zls-flake.url = "github:zigtools/zls";
    zls-flake.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, zig-overlay, flake-utils, zls-flake }:
    let
      inherit (nixpkgs) lib;

      # flake-utils polyfill
      eachSystem = systems: fn:
        lib.foldl'
          (
            acc: system:
              lib.recursiveUpdate
                acc
                (lib.mapAttrs (_: value: { ${system} = value; }) (fn system))
          )
          { }
          systems;

      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      zig_systems = {
        x86_64-linux = "linux-x86_64";
        aarch64-linux = "linux-aarch64";
        x86_64-darwin = "macos-x86_64";
        aarch64-darwin = "macos-aarch64";
      };
    in
    eachSystem systems (system:
      let
        zig_system = zig_systems.${system};
        pkgs = nixpkgs.legacyPackages.${system};
        zls = zls-flake.packages.${system}.zls;
        zig = zig-overlay.packages.${system}.master;
        zig-2024_11_0-mach = zig-overlay.packages.${system}.master-2024-12-30.overrideAttrs(final: prev: {
          src = pkgs.fetchurl {
            url = "https://pkg.machengine.org/zig/zig-${zig_system}-0.14.0-dev.2577+271452d22.tar.xzz";
            sha256 = prev.src.outputHash;
          };
        });
        zig-2024_10_0-mach = zig-overlay.packages.${system}.master-2024-10-14.overrideAttrs(final: prev: {
          src = pkgs.fetchurl {
            url = "https://pkg.machengine.org/zig/zig-${zig_system}-0.14.0-dev.1911+3bf89f55c.tar.xz";
            sha256 = prev.src.outputHash;
          };
        });
        zig-0_14_0 = zig-overlay.packages.${system}."0.14.0";
        zig-0_13_0 = zig-overlay.packages.${system}."0.13.0";
        zig-0_12_1 = zig-overlay.packages.${system}."0.12.1";
      in
      {
        formatter = pkgs.nixpkgs-fmt;
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = [
            zig
            zls
            pkgs.lldb_16
          ];
        };
        devShells.mach-2024_11_0 = pkgs.mkShell {
          nativeBuildInputs = [
            zig-2024_11_0-mach
            zls
            pkgs.lldb_16
          ];
        };
        devShells.mach-2024_10_0 = pkgs.mkShell {
          nativeBuildInputs = [
            zig-2024_10_0-mach
            zls
            pkgs.lldb_16
          ];
        };
        devShells.zig-0_13_0 = pkgs.mkShell {
          nativeBuildInputs = [
            zig-0_13_0
            zls
            pkgs.lldb_16
          ];
        };
        devShells.zig-0_12_1 = pkgs.mkShell {
          nativeBuildInputs = [
            zig-0_12_1
            zls
            pkgs.lldb_16
          ];
        };
      });
}

