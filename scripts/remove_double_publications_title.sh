#!/usr/bin/env bash
set -euo pipefail

FILE="publications.qmd"
[ -f "$FILE" ] || { echo "✗ $FILE not found"; exit 1; }

# Backup
cp "$FILE" "$FILE.bak.$(date +%s)"

# Remove the in-body "# Publications" heading (keep YAML title block)
perl -0777 -i -pe 's/^[ \t]*#\s*Publications\s*\n+//m' "$FILE"

# Rebuild
rm -rf _site _freeze || true
quarto preview
