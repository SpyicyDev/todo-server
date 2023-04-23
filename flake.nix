{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "nixpkgs";

    flake-utils.url = "github:numtide/flake-utils";
    naersk.url = "github:nix-community/naersk";

    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, naersk, fenix }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = (import nixpkgs) {
          inherit system;
        };

        toolchain = with fenix.packages.${system};
          combine [
            default
            targets.x86_64-unknown-linux-musl.latest.rust-std
            targets.x86_64-pc-windows-gnu.latest.rust-std
            targets.i686-pc-windows-gnu.latest.rust-std
          ];

        # setting up naersk
        naersk' = naersk.lib.${system}.override {
          cargo = toolchain.cargo;
          rustc = toolchain.rustc;
        };

      in rec {
        packages.rustPackage.x86_64-linux = naersk'.buildPackage {
          src = ./.;
          nativeBuildInputs = [ pkgs.pkg-config ];
          buildInputs = [ pkgs.openssl ];
          CARGO_BUILD_TARGET = "x86_64-unknown-linux-gnu";
        };

        packages.dockerImage.x86_64-linux = pkgs.dockerTools.buildImage {
          name = "todo-server";
          config = { Cmd = [ "${self.packages."${system}".rustPackage.x86_64-linux}/bin/todo-server" ]; };
        };

        defaultPackage = packages.rustPackage.x86_64-linux;

        devShell = pkgs.mkShell {
          nativeBuildInputs =  [ fenix.packages.${system}.default ];
        };
      }
    );
}
