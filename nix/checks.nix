{ pkgs, lintPkgs, components, archiveComponents, src, docsShell }:
let
  scripts = {
    sdist-rebuild = {
      runtimeInputs = [ ];
      text = ''
        ${archiveComponents.tests.test}/bin/test
        ${archiveComponents.tests.example}/bin/example
      '';
    };
    unit = {
      runtimeInputs = [ ];
      text = ''
        ${components.tests.test}/bin/test
        ${components.tests.example}/bin/example
      '';
    };
    format-check = {
      runtimeInputs = with lintPkgs; [
        haskellPackages.fourmolu
        haskellPackages.cabal-fmt
        nixfmt-classic
        diffutils
        findutils
      ];
      text = ''
        cd ${src}
        find src tests examples -name '*.hs' -exec fourmolu -m check {} +
        diff -u tasty-bdd.cabal <(cabal-fmt tasty-bdd.cabal)
        nixfmt --check flake.nix nix/*.nix
      '';
    };
    hlint = {
      runtimeInputs = [ lintPkgs.haskellPackages.hlint ];
      text = ''
        cd ${src}
        hlint src tests examples
      '';
    };
    cabal-check = {
      runtimeInputs = [ lintPkgs.cabal-install ];
      text = ''
        cd ${src}
        cabal check
      '';
    };
    workflow-check = {
      runtimeInputs = [ lintPkgs.actionlint ];
      text = ''
        cd ${src}
        actionlint -config-file .github/actionlint.yaml .github/workflows/*.yml
      '';
    };
    docs-check = {
      runtimeInputs = [ lintPkgs.python3 ];
      text = ''
        cd ${src}
        python3 tools/check_presentation.py --no-speech --front README.md README.md docs specs
      '';
    };
  };
  apps = builtins.mapAttrs
    (name: spec: pkgs.writeShellApplication (spec // { inherit name; }))
    scripts;
  mkCheck = name: app:
    pkgs.runCommand name {
      nativeBuildInputs = [ pkgs.glibcLocales ];
      LANG = "C.UTF-8";
      LC_ALL = "C.UTF-8";
    } ''
      ${pkgs.lib.getExe app}
      touch $out
    '';
  mermaid = pkgs.fetchurl {
    url = "https://unpkg.com/mermaid@11.17.2/dist/mermaid.min.js";
    hash = "sha256-WB7X10vZBI0OOpE2OSfXLvIpQtdyJUayf3zCnjU5Drg=";
  };
  docs = pkgs.runCommand "tasty-bdd-docs" {
    nativeBuildInputs = docsShell.nativeBuildInputs ++ docsShell.buildInputs;
    LANG = "C.UTF-8";
    LC_ALL = "C.UTF-8";
  } ''
    cp -R ${src} work
    chmod -R u+w work
    cd work
    mkdir -p docs/assets/javascripts
    cp ${mermaid} docs/assets/javascripts/mermaid.min.js
    mkdocs build --strict --site-dir $out
  '';
in builtins.mapAttrs mkCheck apps // {
  inherit docs;
  library = components.library;
  apps = apps // {
    docs = pkgs.writeShellApplication {
      name = "docs";
      runtimeInputs = [ pkgs.coreutils ];
      text = ''
        test -s ${docs}/index.html
        echo "Strict documentation build: ${docs}"
      '';
    };
  };
}
