#!/usr/bin/env bash
# Diff what two pi releases actually ship: the npm tarballs, not release notes.
#
# usage: diff.sh OLD NEW OUTDIR
# writes OUTDIR/{old,new}/     unpacked packages (for the agent to read)
#        OUTDIR/changelog.md   CHANGELOG entries after OLD up to NEW
#        OUTDIR/config.diff    unified diff of the config-facing surface
#        OUTDIR/stat.txt       changed lines per file in config.diff, largest first
set -euo pipefail

old=$1 new=$2 out=$3
pkg=$(nix eval --raw .#lib.upstream.npmPackage)
base="https://registry.npmjs.org/${pkg}/-/${pkg##*/}"

mkdir -p "$out"
for v in "$old" "$new"; do
  side=$([ "$v" = "$old" ] && echo old || echo new)
  rm -rf "${out:?}/$side" && mkdir -p "$out/$side"
  curl -fsSL "${base}-${v}.tgz" | tar -xz -C "$out/$side" --strip-components=1
done

# Everything a user configures, and the code that defines or migrates it.
surface=(
  README.md
  package.json
  docs
  dist/config.d.ts
  dist/migrations.js
  dist/core/settings-manager.d.ts
  dist/core/model-config.d.ts
  dist/core/resource-loader.d.ts
  dist/core/auth-storage.d.ts
  dist/core/resolve-config-value.d.ts
)
(
  cd "$out"
  for path in "${surface[@]}"; do
    diff -ruN --exclude=images "old/$path" "new/$path" || true
  done
) > "$out/config.diff"

awk '/^\+\+\+ /{f=substr($2, 5)} /^[-+][^-+]/{c[f]++} END{for(k in c) print c[k], k}' \
  "$out/config.diff" | sort -rn > "$out/stat.txt"

awk -v old="## [$old]" 'index($0, old) == 1 { exit } { print }' "$out/new/CHANGELOG.md" > "$out/changelog.md"

echo "config.diff: $(awk '{n+=$1} END{print n+0}' "$out/stat.txt") changed lines in $(wc -l < "$out/stat.txt") files"
