#!/usr/bin/env bash
set -euo pipefail

echo "➜ Forcing BIG, UNCROPPED images by injecting inline <style> into Projects pages…"

# Style block that always wins because it's in-page and loaded last.
STYLE='<style>
/* === FINAL, IN-PAGE OVERRIDES FOR PROJECTS === */
:root { --content-max-width: 1400px; }  /* make page wider so cards/images have room */

/* Widen common grids on the page */
#quarto-document-content .projects-grid,
#quarto-document-content .project-grid,
#quarto-document-content .cards-grid,
#quarto-document-content .quarto-grid,
#quarto-document-content .grid { 
  display: grid; gap: 1.25rem; grid-template-columns: repeat(auto-fit, minmax(520px, 1fr));
}

/* Make ALL images in main content LARGE and NEVER CROPPED */
#quarto-document-content img {
  display: block !important;
  width: 100% !important;
  height: clamp(460px, 38vw, 820px) !important; /* big visible area */
  max-width: none !important; max-height: none !important;
  object-fit: contain !important;               /* show entire image */
  border-radius: 14px; background: rgba(0,0,0,.03);
}

/* If a DIV is used with background-image, make that big + non-cropping too */
#quarto-document-content [style*="background-image"],
#quarto-document-content .project-img {
  width: 100% !important;
  min-height: clamp(460px, 38vw, 820px) !important;
  background-size: contain !important; background-position: center !important; background-repeat: no-repeat !important;
  border-radius: 14px;
}

/* Prevent any parent inside cards from clipping */
#quarto-document-content .project-card, 
#quarto-document-content .project-card * {
  max-height: none !important; overflow: visible !important;
}
</style>
'

# Find likely Projects source files (don’t touch generated _site)
mapfile_files() {
  # Prefer filenames with "project" in them; if none, try any *.qmd whose title mentions Projects
  matches=$(find . -type f \( -iname '*project*.qmd' -o -iname '*projects*.qmd' -o -iname 'projects.md' \) ! -path './_site/*' -print)
  if [ -z "$matches" ]; then
    matches=$(grep -RIl --include='*.qmd' -- '^title:.*[Pp]roject' . || true)
  fi
  printf '%s\n' "$matches"
}

FILES=$(mapfile_files)
if [ -z "$FILES" ]; then
  echo "✗ Could not find a Projects .qmd/.md file. Tell me the exact path (e.g., projects.qmd)."
  exit 1
fi

# Insert the STYLE block just after YAML front-matter if present; otherwise prepend it.
for f in $FILES; do
  echo "→ Patching $f"
  cp "$f" "$f.bak.$(date +%s)"
  if perl -0777 -ne 'exit(!(m/\A---\s*\n.*?\n---\s*\n/s))' "$f"; then
    # Has YAML front matter: inject after the closing '---'
    perl -0777 -i -pe 's/\A(---\s*\n.*?\n---\s*\n)/$1\n__INJECT_STYLE__\n/s' "$f"
    # shell-safe replace of placeholder with actual STYLE
    awk -v repl="$STYLE" '{sub(/__INJECT_STYLE__/ , repl)}1' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
  else
    # No front matter: prepend
    printf '%s\n\n' "$STYLE" | cat - "$f" > "$f.tmp" && mv "$f.tmp" "$f"
  fi
done

# Clean and rebuild preview
rm -rf _site _freeze || true
echo "➜ Launching Quarto preview…"
quarto preview
