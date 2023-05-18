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
        pkgs = nixpkgs.legacyPackages.${system};
        target = "x86_64-unknown-linux-musl";

        cross-pkgs = (import nixpkgs) {
            crossSystem = {
                config = target;
            };
        };

        toolchain = with fenix.packages.${system};
          combine [
            minimal.rustc
            minimal.cargo
            targets.${target}.latest.rust-std
          ];

        # setting up naersk
        naersk' = naersk.lib.${system}.override {
          cargo = toolchain;
          rustc = toolchain;
        };

      in rec {

        packages.rustPackage = naersk'.buildPackage {
            src = ./.;
        };

        packages.x86_64-linux = naersk'.buildPackage {
            src = ./.;
            CARGO_BUILD_TARGET = target;
            CARGO_TARGET_X86_64_UNKNOWN_LINUX_MUSL_LINKER =
            let
                inherit (pkgs.pkgsCross.musl64.stdenv) cc;
            in
                "${cc}/bin/${cc.targetPrefix}cc";
        };

        defaultPackage = packages.rustPackage;

        packages.dockerImage = pkgs.dockerTools.buildImage {
          name = "todo-server";
          config = { Cmd = [ "${self.packages."${system}".x86_64-linux}/bin/todo-server" ]; };
        };

        #devShell = pkgs.mkShell {
        #  nativeBuildInputs =  [ fenix.packages.${system}.default ];
        #};
      }
    );
}
