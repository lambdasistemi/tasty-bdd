# Develop tasty-bdd

## Make a change and verify it

As a contributor, you use the same locked tools and executed checks locally and in CI.

```sh
nix develop --accept-flake-config
just build
just unit
just format
just ci
```

`just build` and `just unit` use `-O0`; packaged Nix builds use `-O2`. CI enables the manual `werror` flag. Published consumers do not inherit `-Werror` by default. `cabal.project` pins the package index and enables all test suites.

```mermaid
flowchart LR
  Spec -->|guides| Change
  Change -->|build and test| Shell
  Change -->|sandbox verification| Flake
  Shell -->|evidence| PR
  Flake -->|evidence| PR
```

The flake's `unit`, `format-check`, `hlint`, `cabal-check`, `workflow-check` and `docs` apps provide focused checks. `nix build .#docs` produces the strict MkDocs site. No Hackage credentials are needed.

## Specify a change

Read `.specify/memory/constitution.md` first. The `.specify/scripts/bash` helpers and `.specify/templates` support numbered features under `specs/`. The modernization is recorded in `specs/001-modernization`. Use `SPECIFY_FEATURE=001-modernization` with helpers when working on the named maintenance branch. Keep spec, plan and task status consistent with evidence.

Spec Kit's agent prompts are installed globally rather than duplicated in this repository. The bundled scripts/templates come from Spec Kit 0.4.2; direct initialization avoided an upstream release-packaging SIGPIPE failure.

CI uses GitHub-hosted runners while the repository belongs to `paolino` and the organization `nixos` runner after transfer to `lambdasistemi`. Runner access and cache credentials must be rechecked after transfer.
