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

        # setting up naersk
        naersk' = pkgs.callPackage naersk {
          cargo = pkgs.rust-bin.beta.latest.default;
          rustc = pkgs.rust-bin.beta.latest.default;
        };

        rustBuild = naersk'.buildPackage {
          name = "todo-server";

          src = ./.;
          nativeBuildInputs = [ pkgs.pkg-config ];
          buildInputs = [ pkgs.openssl ];

          postInstall = "cp ./ca-certificate.crt $out/ca-certificate.crt";
        };
 
        dockerImage = pkgs.dockerTools.buildImage {
          name = "todo-server";
          config = { Cmd = [ "${rustBuild}/bin/todo-server" ]; };
        };

      in rec {
        packages = {
          rustPackage = rustBuild;
          docker = dockerImage;
        };

        defaultPackage = rustBuild; 

        devShell = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [ rust-bin.beta.latest.default ];
        };
      }
    );
}
