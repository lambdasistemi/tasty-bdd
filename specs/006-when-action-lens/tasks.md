# When-action lens tasks

## Slice when-action-lens

- [x] T001 Add a CI-compiled module importing `Test.BDD.Language` and `Control.Monad` unqualified and using `when`; it fails to compile on the unchanged library.
- [x] T002 Export the action lens as `whenAction` with a Haddock comment and migrate every in-repository use.
- [x] T003 Make `api-compat` accept exactly the `when` to `whenAction` rename against the 0.1.0.1 baseline and reject any other difference; describe it in `docs/development.md`.
- [x] T004 Set the version to 0.2.0.0 and add the changelog section with the migration note.
- [x] T005 Pass every CI check.
