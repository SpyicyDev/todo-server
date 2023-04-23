{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "nixpkgs";

    flake-utils.url = "github:numtide/flake-utils";
    naersk.url = "github:nix-community/naersk";

    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs = { self, nixpkgs, flake-utils, naersk, rust-overlay }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = (import nixpkgs) {
          inherit system;
          overlays = [ rust-overlay.overlays.default ];
        };

        rustToolchain = pkgs.rust-bin.beta.latest.default.override {
          targets = [ "x86_64-unknown-linux-gnu" ];
        };


        # setting up naersk
        naersk' = pkgs.callPackage naersk {
          cargo = rustToolchain;
          rustc = rustToolchain;
        };

      in rec {
        packages.rustPackage.x86_64-linux = naersk'.buildPackage {
          src = ./.;
          nativeBuildInputs = [ pkgs.pkg-config ];
          buildInputs = [ pkgs.openssl ];
          cargoBuildOptions = [ "$cargo_release" ''-j "$NIX_BUILD_CORES"'' "--message-format=$cargo_message_format" "--target=x86_64-unknown-linux-gnu" ];
        };

        packages.dockerImage.x86_64-linux = pkgs.dockerTools.buildImage {
          name = "todo-server";
          config = { Cmd = [ "${self.packages."${system}".rustPackage.x86_64-linux}/bin/todo-server" ]; };
        };

        defaultPackage = packages.rustPackage.x86_64-linux;

        devShell = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [ rust-bin.beta.latest.default ];
        };
      }
    );
}
