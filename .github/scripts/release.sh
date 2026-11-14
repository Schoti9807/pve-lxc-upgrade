#!/usr/bin/env bash
# Legt für jede Version aus dem CHANGELOG, zu der es noch keinen Tag gibt,
# einen Tag vX.Y.Z und ein GitHub-Release an.
#  - Tag-Commit: der neueste Commit, in dem VERSION im Skript diese Version hat
#  - Release-Notizen: der passende Abschnitt aus dem aktuellen CHANGELOG.md
#  - Anhang: Release-Upgrade in genau diesem Stand
#  - Als „latest“ markiert wird nur die höchste Version
# Läuft in GitHub Actions (braucht git mit voller Historie, gh und GH_TOKEN).
# Mit DRY_RUN=1 wird nur angezeigt, was passieren würde.
set -euo pipefail

version_at() { git show "$1:Release-Upgrade" 2>/dev/null | sed -n 's/^VERSION="\(.*\)"$/\1/p' | head -n1; }
notes_for()  { awk -v v="$1" '
  /^## / { if (p) exit; if (index($0, "## " v " ") == 1) { p = 1; next } }
  p' CHANGELOG.md | awk 'NF {s = 1} s {a[++n] = $0} END {while (n && a[n] == "") n--; for (i = 1; i <= n; i++) print a[i]}'; }

# Versionen, die einen CHANGELOG-Abschnitt haben
mapfile -t VERSIONS < <(sed -n 's/^## \([0-9][0-9.]*\) .*/\1/p' CHANGELOG.md | sort -V)
((${#VERSIONS[@]})) || { echo "Keine Versionen im CHANGELOG gefunden."; exit 0; }
LATEST=${VERSIONS[-1]}

# neuester Commit je Version (gesamte Historie, auch Commits aus Merges)
declare -A COMMIT=()
while read -r sha; do
  v=$(version_at "$sha")
  [[ -n $v && -z ${COMMIT[$v]:-} ]] && COMMIT[$v]=$sha
done < <(git rev-list --topo-order HEAD -- Release-Upgrade)

git fetch --tags --quiet || true
tmp=$(mktemp -d)
for v in "${VERSIONS[@]}"; do
  tag="v$v"
  if git rev-parse -q --verify "refs/tags/$tag" >/dev/null; then
    echo "$tag: Tag gibt es schon – übersprungen"; continue
  fi
  sha=${COMMIT[$v]:-}
  [[ -n $sha ]] || { echo "$tag: kein Commit mit VERSION=\"$v\" gefunden – übersprungen"; continue; }
  notes_for "$v" >"$tmp/notes.md"
  git show "$sha:Release-Upgrade" >"$tmp/Release-Upgrade"
  latest=false; [[ $v == "$LATEST" ]] && latest=true
  echo "$tag: Release an Commit ${sha:0:7} anlegen (latest=$latest)"
  [[ ${DRY_RUN:-0} == 1 ]] && { sed 's/^/    /' "$tmp/notes.md"; continue; }
  gh release create "$tag" "$tmp/Release-Upgrade" \
    --target "$sha" --title "Release-Upgrade $v" --notes-file "$tmp/notes.md" --latest="$latest"
done
rm -rf "$tmp"
