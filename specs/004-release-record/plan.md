# Release record plan

## Approach

One documentation slice, owned by one commit owner and checked by a persistent auditor. Every statement added must be one of the recorded facts in the spec; anything else about the release stays as it is. Sentences that remain true (release automation absent, 0.1.0.1 Hackage links pointing to GitLab, archives built by `just release-check`) are kept.

## Files in scope

| File | Change |
|---|---|
| `CHANGELOG.md` | 0.1.0.2 heading and publication sentence |
| `README.md` | published package paragraph |
| `docs/releases.md` | candidate wording, publication procedure, diagram |
| `docs/api.md` | "release candidate" wording and diagram node |
| `specs/001-modernization/tasks.md` | appended follow-up after the closing paragraph, if a current-state sentence remains |

## Constraints

- The presentation checker runs over `README.md`, `docs` and `specs`: no index labels of the form letter-plus-number outside code, structural pages keep a Mermaid diagram.
- `mkdocs build --strict` must stay clean.
- No file outside the table changes.
