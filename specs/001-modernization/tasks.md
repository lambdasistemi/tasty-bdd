# Modernization tasks

## Build and preserve published behavior

- [x] Build untouched GitHub on GHC 9.12.3 and retain full output.
- [x] Run the six original tests successfully.
- [x] Compare GitLab ancestry and Hackage source; retain the nine GitLab commits.
- [x] Initialize Spec Kit scripts/templates and filled constitution.
- [x] Modernize Cabal, retire Stack/hpack and preserve API.
- [x] Add locked haskell.nix build, shell, executed checks and apps.
- [x] Add regression coverage for the published dependent-test decorator fix.

## Contribute and review

- [x] Add just recipes, formatting, lint and strict warning gates.
- [x] Add README, user stories, architecture and development documentation.
- [x] Add CI Build Gate, concern jobs, development-shell gate and docs deployment.
- [x] Install PR template; open draft PR; assign and label it.
- [x] Apply labels, workflow permissions, branch rules and Pages settings.
- [x] Initialize wiki or hand off the specific initialization requirement.
- [x] Prepare release configuration and source artifacts without publication.

## Transfer with evidence

- [x] Write transfer runbook covering GitHub redirects, GitLab and Hackage links, settings and recovery.
- [x] Run fresh local gates and effective negative controls.
- [x] Validate source archive and documented example.
- [x] Push the reviewed branch and record CI status and remaining operator steps.

The modernization is pushed to [PR 3](https://github.com/lambdasistemi/tasty-bdd/pull/3). Local checkout/archive gates pass; GitHub CI is tracked on the PR and is not implied green by local results. The authorized ownership transfer is complete and the wiki is published. The operator subsequently requested candidate 0.1.0.2 preparation. PR acceptance and publication remain maintainer steps.
