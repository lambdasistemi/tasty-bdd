# Changelog

## 0.1.0.2 — release candidate

- Verify GHC 9.12.3 support and migrate development from Stack/hpack to Cabal 3.0 and a locked Nix build.
- Point package homepage, source repository and issue links to `lambdasistemi/tasty-bdd` following the repository transfer.
- Bound dependencies and add executable build, package, formatting, lint, documentation and source-archive checks.
- Add regression tests for recursive decorators over Tasty dependencies, including blocked tests after a failed prerequisite.
- Add a compiled example, contributor documentation and Spec Kit records.
- Preserve the public API and published 0.1.0.1 behavior, including the `Succeded` spelling and dependency-wrapper traversal fix.

This candidate has not been uploaded to Hackage or tagged as a release. Fresh compiler evidence covers GHC 9.12.3; older compilers allowed by dependency bounds have not been revalidated.

## 0.1.0.1 — published

The published library and test sources match GitLab master. This release includes the recursive Tasty dependency-wrapper traversal fix; 0.1.0.2 preserves that behavior.
