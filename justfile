# Run these recipes inside nix develop.
default:
    @just --list

build:
    cabal build all --enable-tests -O0 -fwerror

unit:
    cabal test all --enable-tests -O0 -fwerror --test-show-details=direct

format:
    fourmolu -i src tests examples
    cabal-fmt -i tasty-bdd.cabal
    nixfmt flake.nix nix/*.nix

format-check:
    nix run .#format-check

hlint:
    nix run .#hlint

cabal-check:
    cabal check

build-docs:
    nix build .#docs

sdist:
    cabal sdist --output-directory=dist

ci: build unit
    nix flake check --no-eval-cache
