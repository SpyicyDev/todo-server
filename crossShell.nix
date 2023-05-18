with import <nixpkgs> {
  crossSystem = {
    config = "x86_64-unknown-linux-gnu";
  };
};

mkShell {
  buildInputs = [ zlib ]; # your dependencies here
}
