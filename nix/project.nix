{ pkgs, lintPkgs, src ? ../. }:
pkgs.haskell-nix.cabalProject' {
  name = "tasty-bdd";
  inherit src;
  compiler-nix-name = "ghc9123";
  modules = [{
    packages.tasty-bdd.flags.werror = true;
    packages.tasty-bdd.ghcOptions = [ "-O2" ];
  }];
  shell = {
    withHoogle = false;
    buildInputs = with lintPkgs; [
      cabal-install
      just
      nixfmt-classic
      actionlint
      python3
      haskellPackages.fourmolu
      haskellPackages.hlint
      haskellPackages.cabal-fmt
    ];
  };
}
