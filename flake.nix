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
          ];

        # setting up naersk
        naersk' = naersk.lib.${system}.override {
          cargo = toolchain;
          rustc = toolchain;
        };

      in rec {
        packages.rustPackage = naersk'.buildPackage {
          src = ./.;
          doCheck = true;
          nativeBuildInputs = [ pkgs.pkg-config pkgs.pkgsCross.musl64.stdenv.cc.cc ];
          buildInputs = [ pkgs.openssl pkgs.openssl.dev ];
        };

        
        packages.rustPackage-x86_64-linux = pkgs.pkgsCross.musl64.callPackage packages.rustPackage {};

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
