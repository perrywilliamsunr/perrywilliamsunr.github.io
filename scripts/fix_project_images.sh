#!/usr/bin/env bash
set -euo pipefail

echo "➜ Fixing project image cropping…"

# 0) Make sure styles file exists and back it up
mkdir -p styles
touch styles/styles.scss
cp styles/styles.scss "styles/styles.scss.bak.$(date +%s)"

# 1) Replace common cropping rules in any CSS/SCSS
while IFS= read -r f; do
  cp "$f" "$f.bak.$(date +%s)"
  perl -0777 -i -pe 's/object-fit\s*:\s*cover/object-fit: contain !important/ig' "$f"
  perl -0777 -i -pe 's/background-size\s*:\s*cover/background-size: contain; background-repeat: no-repeat; background-position: center/ig' "$f"
done < <(find . -type f \( -name '*.css' -o -name '*.scss' \) ! -path './_site/*' )

# 2) Remove inline height/width on IMG tags that carry class project-img
while IFS= read -r f; do
  cp "$f" "$f.bak.$(date +%s)"
  perl -0777 -i -pe 's/(<img[^>]*class="[^"]*\bproject-img\b[^"]*"[^>]*?)\s+(?:height|width)="[^"]*"(.*?>)/$1$2/ig' "$f"
done < <(find . -type f \( -name '*.qmd' -o -name '*.md' -o -name '*.html' \) ! -path './_site/*' )

# 3) Append a HARD OVERRIDE block (wins even if something else sneaks in later)
cat >> styles/styles.scss <<'CSS'

/* ===== HARD OVERRIDE: show full project images, no cropping ===== */
.projects-grid .project-card img.project-img,
.project-card img.project-img,
.project-card picture > img.project-img,
.project-card > img.project-img {
  width: 100% !important;
  height: auto !important;
  max-height: none !important;
  aspect-ratio: auto !important;
  object-fit: contain !important;   /* guarantees no crop on <img> */
  display: block !important;
}

/* If someone used a DIV with background-image for the pic, make that non-cropping too */
.projects-grid .project-card .project-img,
.project-card .project-img {
  background-size: contain !important;   /* instead of cover */
  background-repeat: no-repeat !important;
  background-position: center !important;
  min-height: auto !important;
  height: auto !important;
  overflow: visible !important;
}

/* Safety: avoid parents clipping the image via fixed height/overflow */
.projects-grid .project-card,
.projects-grid .project-card * {
  max-height: none !important;
  overflow: visible !important;
}
CSS

# 4) Clean build artifacts and relaunch preview
rm -rf _site _freeze || true
echo "➜ Launching Quarto preview…"
quarto preview
