#!/usr/bin/env bash
set -euo pipefail
source_archive=$1
artifacts=$2
mkdir -p "$artifacts"
artifacts=$(realpath "$artifacts")
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
tar -xzf "$source_archive" -C "$scratch"
cd "$scratch"/tasty-bdd-*
chmod -R u+w .
# All dependencies come from the locked compiler environment, even in a sandbox.
printf 'active-repositories: :none\n' > cabal.project.local
printf 'remote-repo-cache: %s\nstore-dir: %s\nlogs-dir: %s\nworld-file: %s\n' \
  "$scratch/cache" "$scratch/store" "$scratch/logs" "$scratch/world" > "$scratch/cabal.config"
cabal --config-file="$scratch/cabal.config" check
cabal --config-file="$scratch/cabal.config" build all --offline --enable-tests -O0 -f-werror
cabal --config-file="$scratch/cabal.config" test all --offline --enable-tests -O0 -f-werror --test-show-details=direct
cabal --config-file="$scratch/cabal.config" haddock lib:tasty-bdd --offline --haddock-for-hackage -O0 -f-werror 2>&1 | tee "$artifacts/haddock.log"
python3 - "$artifacts/haddock.log" <<'PY'
import pathlib, re, sys
log = pathlib.Path(sys.argv[1]).read_text()
coverage = re.findall(r"^\s*(\d+)%.* in '([^']+)'", log, re.M)
expected = {'System.CaptureStdout', 'Test.BDD.Language', 'Test.BDD.LanguageFree', 'Test.Tasty.Bdd'}
assert {name for _, name in coverage} == expected, 'Missing module documentation coverage'
assert all(int(percent) == 100 for percent, _ in coverage), coverage
assert 'is out of scope' not in log, 'Unresolved local Haddock reference'
assert 'Missing documentation for:' not in log, 'Undocumented public declaration'
PY
cp "$source_archive" dist-newstyle/*-docs.tar.gz "$artifacts/"
(cd "$artifacts" && sha256sum ./*.tar.gz > SHA256SUMS)
echo "Hackage source and Haddock bundles checked: $artifacts"
