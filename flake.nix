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
            minimal.rustc
            minimal.cargo
            targets.x86_64-unknown-linux-musl.latest.rust-std
          ];

        # setting up naersk
        naersk' = naersk.lib.${system}.override {
          cargo = toolchain;
          rustc = toolchain;
        };

      in rec {
        packages.rustPackage-x86_64-linux = naersk'.buildPackage {
          src = ./.;
          doCheck = true;
          nativeBuildInputs = [ pkgs.pkg-config pkgs.stdenv.cc ];
          buildInputs = [ pkgs.openssl ];
          CARGO_BUILD_TARGET = "x86_64-unknown-linux-musl";
          TARGET_CC="x86_64-linux-musl-gcc";
        };

        packages.dockerImage = pkgs.dockerTools.buildImage {
          name = "todo-server";
          config = { Cmd = [ "${self.packages."${system}".rustPackage.x86_64-linux}/bin/todo-server" ]; };
        };

        devShell = pkgs.mkShell {
          nativeBuildInputs =  [ fenix.packages.${system}.default ];
        };
      }
    );
}
