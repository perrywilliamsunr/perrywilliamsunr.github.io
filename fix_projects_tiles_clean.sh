#!/usr/bin/env bash
set -euo pipefail

echo "➜ Cleaning Projects page of injected junk and fixing tiles…"

# 1) Locate Projects source files (ignore generated _site)
found_files=""
while IFS= read -r f; do found_files="${found_files}
${f}"; done < <(find . -type f \( -name '*projects*.qmd' -o -name '*project*.qmd' -o -name 'projects.md' \) ! -path './_site/*' 2>/dev/null)
found_files="$(echo "$found_files" | sed '/^\s*$/d' || true)"

if [ -z "$found_files" ]; then
  echo "✗ Could not find a Projects .qmd/.md file. Rename it to include 'projects' and rerun."
  exit 1
fi

# 2) Clean each Projects file:
#    - remove our placeholder 'INJECT_STYLE' lines
#    - remove stray fenced div markers ':::' we accidentally left
#    - remove any inline <style>…</style> blocks we injected earlier
while IFS= read -r file; do
  [ -z "$file" ] && continue
  echo "→ Cleaning $file"
  cp "$file" "$file.bak.$(date +%s)"

  # Remove any line containing INJECT_STYLE
  sed -i '' '/INJECT_STYLE/d' "$file" || true

  # Remove bare fenced-div lines we introduced (keeps your normal content)
  # Only targets lines that START with ::: (avoids touching code blocks etc.)
  sed -i '' -E '/^[[:space:]]*:::/d' "$file" || true

  # Strip any inline <style>…</style> blocks we added before (page will use stylesheet instead)
  perl -0777 -i -pe 's/<style\b[^>]*>.*?<\/style>\s*//sig' "$file" || true
done <<EOF2
$found_files
EOF2

# 3) Append last-wins CSS to stylesheet to force a real tile grid + big, uniform, NO-CROP images
mkdir -p styles
touch styles/styles.scss
cp styles/styles.scss "styles/styles.scss.bak.$(date +%s)"

cat >> styles/styles.scss <<'CSS'

/* ===== FINAL: Projects tiles — big, uniform, no-crop images ===== */

/* Make typical projects grids render as tiles (2–3 columns responsive) */
#quarto-document-content .projects-grid,
#quarto-document-content .project-grid,
#quarto-document-content .cards-grid,
#quarto-document-content .quarto-grid {
  display: grid !important;
  gap: 1.25rem !important;
  grid-template-columns: repeat(auto-fit, minmax(360px, 1fr)) !important;
  align-items: stretch !important;
}

/* Tile/card basics */
#quarto-document-content .project-card {
  display: flex !important;
  flex-direction: column !important;
  gap: .7rem !important;
  padding: 1rem !important;
  background: #f7efe5 !important;
  border-radius: 16px !important;
  box-shadow: 0 2px 8px rgba(0,0,0,.06) !important;
  height: 100% !important;
}

/* Big, UNIFORM header area for images, but DO NOT CROP */
#quarto-document-content .project-card img {
  width: 100% !important;
  height: 420px !important;        /* ← tile header height (bump to 480px if you want bigger) */
  object-fit: contain !important;  /* show the whole image (no cropping) */
  display: block !important;
  border-radius: 12px !important;
  background: rgba(0,0,0,.04) !important;
}

/* If the "image" is actually a DIV with background-image */
#quarto-document-content .project-card .project-img {
  width: 100% !important;
  height: 420px !important;
  background-size: contain !important;
  background-position: center !important;
  background-repeat: no-repeat !important;
  border-radius: 12px !important;
}

@media (min-width: 1400px) {
  #quarto-document-content .project-card img,
  #quarto-document-content .project-card .project-img {
    height: 480px !important;      /* a little taller on big screens */
  }
}

/* Belt & suspenders: never let parents clip the image */
#quarto-document-content .project-card,
#quarto-document-content .project-card * {
  max-height: none !important;
  overflow: visible !important;
}
CSS

# 4) Clean build artifacts and relaunch preview
echo "➜ Rebuilding preview…"
rm -rf _site _freeze || true
quarto preview
