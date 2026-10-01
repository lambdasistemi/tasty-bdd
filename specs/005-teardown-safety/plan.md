# Plan

## Strategy

One bisect-safe slice, `teardown-safety`, owned by one commit owner:

1. RED: add the regression and preservation tests to the `test` suite; on the unchanged library the five new-behaviour cases fail and the preserved cases pass.
2. GREEN: make both runners release through failures (constructor runner in `src/Test/Tasty/Bdd.hs`, free runner in `src/Test/BDD/LanguageFree.hs` and its `IsTest` instance), keeping every export, type and signature.
3. Docs: rewrite the teardown paragraph of `docs/stories/scenarios.md` and add a changelog entry under an unreleased heading.

## Constraints

- `TestableMonad m` provides `MonadCatch` (not `MonadMask`); no constraint may be added to any exported signature or class. Masking, when used, is applied within the existing constraints or in `IO` around `runCase`.
- Fail-fast on: a failed constructor scenario skips teardown (unchanged). The free runner's fail-fast handling is unchanged.
- No version bump, tag, upload, or change to `nix/`, `tools/`, CI workflows, or the `api-compat` baseline.

## Files

`src/Test/Tasty/Bdd.hs`, `src/Test/BDD/LanguageFree.hs`, `tests/` (new modules allowed), the `test-suite test` stanza of `tasty-bdd.cabal` only if a test module or dependency is added, `docs/stories/scenarios.md`, `CHANGELOG.md`, `specs/005-teardown-safety/tasks.md` (task stamps only).

## Verification

The ignored ticket gate runs the path fence and every command of `.github/workflows/ci.yml` (build gate, check matrix including `unit` and `api-compat`, dev-shell build and unit).
