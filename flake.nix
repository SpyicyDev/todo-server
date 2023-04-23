{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "nixpkgs";

    flake-utils.url = "github:numtide/flake-utils";
    naersk.url = "github:nix-community/naersk";

    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, flake-utils, naersk, rust-overlay }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = (import nixpkgs) {
          inherit system;
            overlays = [ rust-overlay.overlays.default ];
        };

        toolchain = pkgs.rust-bin.beta.latest.default.override {
          extensions = [ "rust-src" ];
          targets = [ "x86_64-unknown-linux-gnu" ];
        };

        # setting up naersk
        naersk' = naersk.lib.${system}.override {
          cargo = toolchain;
          rustc = toolchain;
        };

      in rec {
        packages.rustPackage.x86_64-linux = naersk'.buildPackage {
          src = ./.;
          nativeBuildInputs = [ pkgs.pkg-config ];
          buildInputs = [ pkgs.openssl ];
          CARGO_BUILD_TARGET = "x86_64-unknown-linux-gnu";
        };

        packages.dockerImage = pkgs.dockerTools.buildImage {
          name = "todo-server";
          config = { Cmd = [ "${self.packages."${system}".rustPackage.x86_64-linux}/bin/todo-server" ]; };
        };

        defaultPackage = packages.rustPackage.x86_64-linux;

        devShell = pkgs.mkShell {
          nativeBuildInputs =  [ pkgs.rust-bin.beta.latest.default ];
        };
      }
    );
}
