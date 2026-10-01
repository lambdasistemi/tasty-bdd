#!/usr/bin/env bash
set -euo pipefail
baseline=$1
candidate=$2
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
modules=(
  Test.Tasty.Bdd
  Test.BDD.Language
  Test.BDD.LanguageFree
  System.CaptureStdout
)
browse() {
  local source=$1
  local output=$2
  : > "$output"
  # One session per module, each headed by its name, so a difference is
  # attributed to the module that exports it.
  for module in "${modules[@]}"; do
    echo "-- :browse $module" >> "$output"
    (
      cd "$source"
      ghci -ignore-dot-ghci -v0 -isrc \
        src/Test/Tasty/Bdd.hs src/Test/BDD/Language.hs \
        src/Test/BDD/LanguageFree.hs src/System/CaptureStdout.hs \
        <<< ":browse $module"
    ) >> "$output" 2>> "$output.errors"
  done
  # GHCi can return success after a failed load: errors must also fail the gate.
  if grep -E 'error:|Failed,|Could not find module' "$output.errors"; then
    cat "$output.errors" >&2
    return 1
  fi
  grep -Fx 'onEach :: (TestTree -> TestTree) -> TestTree -> TestTree' "$output"
}
browse "$baseline" "$scratch/published.api"
browse "$candidate" "$scratch/candidate.api"
# The one accepted change since 0.1.0.1: the when lens of Test.BDD.Language
# is exported as whenAction with the same type. Apply exactly that rename to
# the baseline; any other difference still fails the comparison below.
python3 - "$scratch/published.api" <<'PY'
import pathlib, sys
path = pathlib.Path(sys.argv[1])
lines = path.read_text().split('\n')
lens = [
    'when ::',
    '  Functor f => (m t -> f (m t)) -> BDDTest m t q -> f (BDDTest m t q)',
]
section = None
found = []
for index, line in enumerate(lines):
    if line.startswith('-- :browse '):
        section = line[len('-- :browse '):]
    elif section == 'Test.BDD.Language' and lines[index:index + 2] == lens:
        found.append(index)
assert len(found) == 1, f'expected one when lens in Test.BDD.Language, found {len(found)}'
lines[found[0]] = 'whenAction ::'
path.write_text('\n'.join(lines))
PY
diff -u "$scratch/published.api" "$scratch/candidate.api"
echo 'Public API matches published tasty-bdd 0.1.0.1 on GHC 9.12.3, except the when lens of Test.BDD.Language, renamed whenAction with the same type.'
