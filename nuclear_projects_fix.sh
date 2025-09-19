#!/usr/bin/env bash
set -euo pipefail

echo "➜ Creating last-wins overrides for BIG, UNCROPPED images…"

# Ensure style dir + backup
mkdir -p styles
touch styles/styles.scss
cp styles/styles.scss "styles/styles.scss.bak.$(date +%s)"

# Write a FINAL override file that will always match and always win
cat > styles/final-overrides.css <<'CSS'
/* ===== NUCLEAR OVERRIDES (Projects) =====
   Make cards wide and ALL images in main content BIG + NOT CROPPED.
   These selectors are broad on purpose so they always hit.
*/

/* Wider grids so cards/images get real width */
#quarto-document-content .projects-grid,
#quarto-document-content .project-grid,
#quarto-document-content .cards-grid,
#quarto-document-content .quarto-grid,
#quarto-document-content .grid,
#quarto-document-content .row {
  display: grid;
  gap: 1.25rem;
  grid-template-columns: repeat(auto-fit, minmax(520px, 1fr));
}

/* BIG, uncropped images anywhere in main content (projects page included) */
#quarto-document-content img {
  display: block !important;
  width: 100% !important;
  height: clamp(460px, 38vw, 820px) !important; /* BIG visible height */
  max-width: none !important;
  max-height: none !important;
  object-fit: contain !important;               /* show whole image */
  border-radius: 14px;
  background: rgba(0,0,0,.03);
}

/* If "images" are actually backgrounds on divs, make those big + non-cropping too */
#quarto-document-content [style*="background-image"],
#quarto-document-content .project-img {
  width: 100% !important;
  min-height: clamp(460px, 38vw, 820px) !important;
  background-size: contain !important;
  background-position: center !important;
  background-repeat: no-repeat !important;
  border-radius: 14px;
}

/* Prevent parents from clipping */
#quarto-document-content .project-card,
#quarto-document-content .project-card * {
  max-height: none !important;
  overflow: visible !important;
}
CSS

# Import the overrides LAST so they win the cascade
if ! grep -q 'final-overrides.css' styles/styles.scss; then
  printf '\n/* MUST BE LAST: import nuclear overrides */\n@import "final-overrides.css";\n' >> styles/styles.scss
fi

# Clean old builds and relaunch preview
rm -rf _site _freeze || true
echo "➜ Launching Quarto preview…"
quarto preview
