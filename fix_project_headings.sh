#!/usr/bin/env bash
set -euo pipefail

FILE="./projects.qmd"
[ -f "$FILE" ] || { echo "projects.qmd not found"; exit 1; }

# Backup
cp "$FILE" "$FILE.bak.$(date +%s)"

# Convert any line that starts with "#### " into a real <h4>…</h4> heading
# and ensure a blank line after it so the following paragraph is separate.
perl -0777 -i -pe '
  s/^[ \t]*####[ \t]+(.+?)\s*$/<h4>$1<\/h4>\n/mg;
' "$FILE"

# Rebuild
rm -rf _site _freeze || true
quarto preview
