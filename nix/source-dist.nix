{ pkgs, src }:
pkgs.runCommand "tasty-bdd-source-dist" {
  nativeBuildInputs = [ pkgs.cabal-install pkgs.gnutar ];
} ''
  export HOME=$TMPDIR/home
  mkdir -p "$HOME" $out
  cp -R ${src} work
  chmod -R u+w work
  cd work
  cabal sdist --output-directory=$out
  mkdir $out/source
  tar -xzf "$out"/tasty-bdd-*.tar.gz --strip-components=1 -C $out/source
''
