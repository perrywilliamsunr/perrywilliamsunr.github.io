#!/usr/bin/env bash
set -euo pipefail

echo "➜ Cleaning any leftover project-img fenced divs causing ::: warnings (safe)…"
# Unwrap only our prior wrappers: ::: {.project-img-wrap} … :::
# (Leaves other fenced divs alone.)
find . -type f \( -name '*projects*.qmd' -o -name '*project*.qmd' -o -name 'projects.qmd' \) ! -path './_site/*' -print0 \
| while IFS= read -r -d '' f; do
  cp "$f" "$f.bak.$(date +%s)"
  perl -0777 -i -pe 's/:::\s*\{\.project-img-wrap\}\s*\n(.*?)\n:::/\1/sg' "$f"
done

echo "➜ Appending last-wins CSS overrides to make images BIG, tile-consistent, no cropping…"
mkdir -p styles
touch styles/styles.scss
cp styles/styles.scss "styles/styles.scss.bak.$(date +%s)"

cat >> styles/styles.scss <<'CSS'

/* ===== OVERRIDES: Project tiles — BIG images, uniform height, NO CROP ===== */

/* Common projects grids: keep them as tiles */
#quarto-document-content .projects-grid,
#quarto-document-content .project-grid,
#quarto-document-content .cards-grid,
#quarto-document-content .quarto-grid {
  display: grid;
  gap: 1.25rem;
  grid-template-columns: repeat(auto-fit, minmax(360px, 1fr));
  align-items: stretch;
}

/* Make card images BIG and uniform-height (tile look), but show the whole image */
#quarto-document-content .project-card img,
#quarto-document-content .projects-grid img,
#quarto-document-content .project-grid img,
#quarto-document-content .cards-grid img,
#quarto-document-content .quarto-grid .card img {
  display: block !important;
  width: 100% !important;
  height: 380px !important;          /* ← set tile header height (bump to 440px if you want bigger) */
  object-fit: contain !important;     /* show full image, no cropping */
  border-radius: 12px;
  background: rgba(0,0,0,.04);
}

/* Wider screens: slightly taller tiles */
@media (min-width: 1400px) {
  #quarto-document-content .project-card img,
  #quarto-document-content .projects-grid img,
  #quarto-document-content .project-grid img,
  #quarto-document-content .cards-grid img,
  #quarto-document-content .quarto-grid .card img {
    height: 440px !important;
  }
}
CSS

echo "➜ Rebuilding preview (clear caches)…"
rm -rf _site _freeze || true
quarto preview
