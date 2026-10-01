#!/usr/bin/env bash
set -euo pipefail
baseline=$1
candidate=$2
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
browse() {
  local source=$1
  local output=$2
  (
    cd "$source"
    ghci -ignore-dot-ghci -v0 -isrc \
      src/Test/Tasty/Bdd.hs src/Test/BDD/Language.hs \
      src/Test/BDD/LanguageFree.hs src/System/CaptureStdout.hs <<'GHC'
:browse Test.Tasty.Bdd
:browse Test.BDD.Language
:browse Test.BDD.LanguageFree
:browse System.CaptureStdout
:quit
GHC
  ) > "$output" 2> "$output.errors"
  # GHCi can return success after a failed load: errors must also fail the gate.
  if grep -E 'error:|Failed,|Could not find module' "$output.errors"; then
    cat "$output.errors" >&2
    return 1
  fi
  grep -Fx 'onEach :: (TestTree -> TestTree) -> TestTree -> TestTree' "$output"
}
browse "$baseline" "$scratch/published.api"
browse "$candidate" "$scratch/candidate.api"
diff -u "$scratch/published.api" "$scratch/candidate.api"
echo 'Public API matches published tasty-bdd 0.1.0.1 on GHC 9.12.3.'
