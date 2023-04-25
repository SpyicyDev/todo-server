{naesrk', pkgs }: naersk'.buildPackage {
  src = ./.;
  doCheck = true;
  nativeBuildInputs = [ pkgs.pkg-config pkgs.pkgsStatic.stdenv.cc ];
  buildInputs = [ pkgs.openssl pkgs.openssl.dev ];
  CARGO_BUILD_TARGET = "x86_64-unknown-linux-musl";
  CARGO_BUILD_RUSTFLAGS = "-C target-feature=+crt-static";
}