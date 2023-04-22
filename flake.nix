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

        naersk' = pkgs.callPackage naersk {};

      in rec {
        # For `nix build` & `nix run`:
        defaultPackage = naersk'.buildPackage {
          src = ./.;
          nativeBuildInputs = [ pkgs.pkg-config ];
          buildInputs = [ pkgs.openssl ];
        };

        defaultApp = {
          type = "app";
          program = "${defaultPackage}/bin/todo-server";
        };


        # For `nix develop` (optional, can be skipped):
        devShell = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [ rust-bin.beta.latest.default ];
        };
      }
    );
}
