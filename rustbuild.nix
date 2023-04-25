{naersk', pkgs }: naersk'.buildPackage {
  src = ./.;
  doCheck = true;
  nativeBuildInputs = [ pkgs.pkg-config ];
  buildInputs = [ pkgs.openssl pkgs.openssl.dev ];
}