#!/usr/bin/env bash
set -euo pipefail

echo "➜ Making project images large and uncropped…"

# Ensure stylesheet exists and back it up
mkdir -p styles
touch styles/styles.scss
cp styles/styles.scss "styles/styles.scss.bak.$(date +%s)"

# Append hard overrides: wider cards + large, no-crop images
cat >> styles/styles.scss <<'CSS'
/* ===== OVERRIDE: Larger cards & big, uncropped project images ===== */

/* Wider cards so the image has real width */
.projects-grid {
  display: grid;
  gap: 1.25rem;
  grid-template-columns: 1fr; /* mobile: 1 column */
}
@media (min-width: 900px) {
  .projects-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); }  /* desktop: 2 wide columns */
}
@media (min-width: 1400px) {
  .projects-grid { grid-template-columns: repeat(3, minmax(0, 1fr)); }  /* ultra-wide: 3 cols */
}

/* Make each project image a large, consistent header area with NO cropping */
.projects-grid .project-card img.project-img {
  width: 100% !important;
  max-width: none !important;
  aspect-ratio: 4 / 3 !important;    /* change to 3/2 for taller, 16/9 for wider */
  height: auto !important;           /* height derived from aspect-ratio */
  max-height: none !important;
  object-fit: contain !important;    /* show the whole image */
  display: block !important;
  border-radius: 12px;
  background: rgba(0,0,0,.03);
}
CSS

# Rebuild preview
rm -rf _site _freeze || true
echo "➜ Launching Quarto preview…"
quarto preview
