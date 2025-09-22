#!/usr/bin/env bash
set -euo pipefail

echo "➜ Adding markdown rendering to project containers and fixing image cropping…"

# 1) Add markdown="1" to any HTML project wrappers so ### headings render
files=$(grep -RlE '<div[^>]*(projects-grid|project-card)' --include='*.qmd' --include='*.md' . || true)
if [[ -n "${files}" ]]; then
  while IFS= read -r f; do
    ts=$(date +%s)
    cp "$f" "$f.bak.$ts"

    # Add markdown="1" to tags with class projects-grid (if not already present)
    perl -0777 -i -pe 's/<div(?![^>]*markdown="1")([^>]*class="[^"]*\bprojects-grid\b[^"]*"[^>]*)>/<div\1 markdown="1">/g' "$f"
    # Add markdown="1" to tags with class project-card (if not already present)
    perl -0777 -i -pe 's/<div(?![^>]*markdown="1")([^>]*class="[^"]*\bproject-card\b[^"]*"[^>]*)>/<div\1 markdown="1">/g' "$f"
  done <<< "$files"
else
  echo "   (No .qmd/.md files with projects-grid/project-card found; skipping markdown fix.)"
fi

# 2) Append CSS overrides so images show fully (no crop) and cards stack cleanly
mkdir -p styles
touch styles/styles.scss
cp styles/styles.scss "styles/styles.scss.bak.$(date +%s)"
cat >> styles/styles.scss <<'CSS'

/* ===== FIX: Project cards & images (no external assets required) ===== */
.project-img,
img.project-img {
  width: 100%;
  height: auto !important;     /* ensure no forced height */
  display: block;
  border-radius: 12px;
  object-fit: contain !important;  /* avoid cropping if aspect is enforced elsewhere */
  background: transparent;
}
.project-card {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}
.project-card p { margin: 0; }
CSS

# 3) Clean any previous build artifacts and re-run preview
rm -rf _site _freeze || true
echo "➜ Launching Quarto preview…"
quarto preview
