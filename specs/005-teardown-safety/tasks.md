# Teardown safety tasks

## Slice teardown-safety

- [x] T001 Add tests for the cases and failure-reporting rules; the five new-behaviour cases fail on the unchanged library.
- [x] T002 Release every acquired resource in the constructor runner when a step or acquisition throws, with fail-fast off.
- [x] T003 Run every teardown even when one throws, in both runners, keeping the original failure as the reported reason.
- [x] T004 Report a scenario failed when its steps pass and a teardown throws, in both runners.
- [x] T005 Describe the guarantee on the scenarios page and in the changelog.
- [x] T006 Pass every CI check with the public API unchanged.
