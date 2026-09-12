{ pkgs, lintPkgs, components, archiveComponents, src, docsShell, buildShell
, sourceDist }:
let
  compilerInputs = buildShell.nativeBuildInputs ++ buildShell.buildInputs;
  scriptInputs = with lintPkgs; [
    coreutils
    gnutar
    gzip
    gnugrep
    diffutils
    python3
  ];
  publishedArchive = pkgs.fetchurl {
    url =
      "https://hackage.haskell.org/package/tasty-bdd-0.1.0.1/tasty-bdd-0.1.0.1.tar.gz";
    sha256 = "f13238d7445fc5afeb9c6cda858f60f1c3b90247b7f369ea9cf65605074a41b5";
  };
  published = pkgs.runCommand "tasty-bdd-published-0.1.0.1" {
    nativeBuildInputs = [ pkgs.gnutar pkgs.gzip ];
  } ''
    mkdir -p $out
    tar -xzf ${publishedArchive} --strip-components=1 -C $out
  '';
  hackageRelease = pkgs.runCommand "tasty-bdd-hackage-release" {
    nativeBuildInputs = compilerInputs ++ scriptInputs ++ [ pkgs.glibcLocales ];
    LANG = "C.UTF-8";
    LC_ALL = "C.UTF-8";
  } ''
    bash ${src}/tools/check-hackage.sh ${sourceDist}/tasty-bdd-*.tar.gz $out
  '';
  scripts = {
    api-compat = {
      runtimeInputs = compilerInputs ++ scriptInputs;
      text = ''
        bash ${src}/tools/check-api.sh ${published} ${src}
      '';
    };
    hackage-quality = {
      runtimeInputs = [ pkgs.coreutils ];
      text = ''
        cd ${hackageRelease}
        sha256sum -c SHA256SUMS
        cat haddock.log
      '';
    };
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
    python3 tools/embed-haddock.py ${hackageRelease}/*-docs.tar.gz docs/haddock
    mkdocs build --strict --site-dir $out
    python3 tools/embed-haddock.py ${hackageRelease}/*-docs.tar.gz $out/haddock --check
  '';
in builtins.mapAttrs mkCheck apps // {
  inherit docs hackageRelease;
  library = components.library;
  apps = apps // {
    pages-smoke = pkgs.writeShellApplication {
      name = "pages-smoke";
      runtimeInputs = [ lintPkgs.python3 ];
      text = ''
        python3 ${src}/tools/check-pages.py ${docs} "$@"
      '';
    };
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
