#!/usr/bin/env bash
set -euo pipefail

echo "➜ Ensuring stylesheet and backups…"
mkdir -p styles
touch styles/styles.scss
cp styles/styles.scss "styles/styles.scss.bak.$(date +%s)"

echo "➜ (Safety) Relax any hard cropping rules in your *.css/*.scss (best effort)…"
find . -type f \( -name '*.css' -o -name '*.scss' \) ! -path './_site/*' -print0 \
| while IFS= read -r -d '' f; do
  cp "$f" "$f.bak.$(date +%s)"
  # Convert 'cover' to 'contain' so the whole image can show
  perl -0777 -i -pe 's/object-fit\s*:\s*cover/object-fit: contain/ig' "$f"
  perl -0777 -i -pe 's/background-size\s*:\s*cover/background-size: contain/ig' "$f"
  # Remove tiny fixed heights on project images (keep other rules intact)
  perl -0777 -i -pe 's/(\.project-img[^{]*\{[^}]*?)height\s*:\s*\d+px\s*;?/$1/ig' "$f"
done

echo "➜ Appending FINAL last-wins overrides (guarantee BIG + NO CROP)…"
cat >> styles/styles.scss <<'CSS'

/* ===================== FINAL OVERRIDES: PROJECT CARDS & IMAGES ===================== */

/* Make the grid wide so cards (and images) aren't squeezed */
.projects-grid, .project-grid, .cards-grid {
  display: grid;
  gap: 1.25rem;
  grid-template-columns: repeat(auto-fit, minmax(520px, 1fr)); /* min 520px per card */
}

/* Cards should not clip or constrain */
.projects-grid .project-card,
.project-grid .project-card,
.cards-grid .project-card {
  max-width: none !important;
  overflow: visible !important;
}

/* BIG, UNCROPPED images inside cards */
.projects-grid .project-card img.project-img,
.project-grid .project-card img.project-img,
.cards-grid   .project-card img.project-img,
.projects-grid .project-card picture img,
.project-grid .project-card picture img,
.cards-grid   .project-card picture img,
.projects-grid .project-card img,
.project-grid .project-card img,
.cards-grid   .project-card img {
  display: block !important;
  width: 100% !important;
  /* Force a generous visible size across screen sizes */
  height: clamp(420px, 38vw, 780px) !important;
  max-width: none !important;
  max-height: none !important;
  object-fit: contain !important;     /* show entire image; NO CROPPING */
  border-radius: 14px;
  background: rgba(0,0,0,.03);
}

/* If your “image” is a DIV with a background image, make that big and non-cropping too */
.projects-grid .project-card .project-img,
.project-grid .project-card .project-img,
.cards-grid   .project-card .project-img,
.projects-grid .project-card [style*="background-image"],
.project-grid .project-card [style*="background-image"],
.cards-grid   .project-card [style*="background-image"] {
  width: 100% !important;
  min-height: clamp(420px, 38vw, 780px) !important;  /* big visible area */
  background-size: contain !important;
  background-repeat: no-repeat !important;
  background-position: center !important;
  border-radius: 14px;
}

/* Belt & suspenders: kill hidden overflows/heights anywhere inside cards */
.projects-grid .project-card *,
.project-grid .project-card *,
.cards-grid   .project-card * {
  max-height: none !important;
  overflow: visible !important;
}
CSS

echo "➜ Cleaning build artifacts and launching preview…"
rm -rf _site _freeze || true
quarto preview
