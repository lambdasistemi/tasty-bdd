# tasty-bdd constitution

Version: 1.0.0. Ratified: 2026-09-11.

## Core principles

1. Documentation, specifications, vision and acceptance criteria outrank implementation. Code can be regenerated from a good record; the record cannot be regenerated from code. Every change ships its user-facing documentation and executable acceptance evidence together.
2. Preserve the published BDD API, providers, ordering and teardown behavior during tooling modernization. Changes to those promises need an explicit product decision. Retain the published `Succeded` constructor spelling for compatibility.
3. Use a locked Nix flake and GHC 9.12.3. Local and CI checks execute the same tools. Build, tests, formatting, lint, package metadata and documentation checks must fail when their subject is broken.
4. Keep the Cabal package description authoritative; do not maintain generated hpack and handwritten Cabal descriptions concurrently. Keep package metadata suitable for Hackage.
5. Keep source provenance: preserve the GitLab commits that follow GitHub and match the published library source. Repository ownership and package publication are separate operations.

## Development workflow

Specifications describe user outcomes before implementation. Plans record choices and tasks track evidence. Use focused conventional commits on a branch and a reviewed pull request; no direct default-branch changes, force pushes or merges with failing required checks. Test development changes at `-O0`; packaged CI builds use `-O2`. Enable strict warnings in CI through a manual Cabal flag, not for downstream users by default.

## Governance

A maintainer approves changes to this constitution with a rationale and corresponding spec updates. Repository transfer is an operator action described in a reviewed runbook. No workflow in this modernization publishes to Hackage; a future release requires a separate version and publication decision. Never reuse an already published version for an upload. No new API or provider decisions are implied by a toolchain update.
