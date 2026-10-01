# Plan

## Strategy

One bisect-safe slice, `when-action-lens`, owned by one commit owner:

1. RED: add the compile-proof module to a CI-built suite. On the unchanged library the suite fails to compile with an ambiguous `when`.
2. GREEN: rename the exported lens to `whenAction` with a Haddock comment and migrate its use in `interpret`.
3. Compatibility: make `api-compat` accept exactly the rename, and nothing else, against the unchanged 0.1.0.1 baseline.
4. Release metadata: version 0.2.0.0, changelog section with the migration note, the `api-compat` description in `docs/development.md`.

## Constraints

- The 0.1.0.1 baseline archive and its hash in `nix/checks.nix` stay as they are; the accepted rename is expressed against that baseline, not by replacing it.
- No other export, type, signature, instance or behaviour changes. No dependency is added to the library.
- No tag, upload, or CI workflow change.

## Files

`src/Test/BDD/Language.hs`, `src/Test/Tasty/Bdd.hs` (only if it names the lens), `tests/`, `examples/`, `tasty-bdd.cabal` (version line and test-suite stanzas only), `tools/check-api.sh`, `nix/checks.nix` (api-compat only), `CHANGELOG.md`, `docs/development.md`, `specs/006-when-action-lens/tasks.md` (task stamps only).

## Verification

The ignored ticket gate runs the path and cabal fences, the version check, and every command of `.github/workflows/ci.yml` (build gate, check matrix including `unit`, `api-compat` and `hackage-quality`, dev-shell build and unit). The `api-compat` rejection of extra changes is shown by running the candidate check against deliberately altered scratch trees.
