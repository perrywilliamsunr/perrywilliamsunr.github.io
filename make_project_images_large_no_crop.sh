#!/usr/bin/env bash
set -euo pipefail

echo "➜ Backing up and wrapping project images…"

# 1) Find source content files
mapfile -t CONTENT < <(find . -type f \( -name '*.qmd' -o -name '*.md' -o -name '*.html' \) ! -path './_site/*' )

for f in "${CONTENT[@]}"; do
  cp "$f" "$f.bak.$(date +%s)"

  # Wrap HTML <img ... class="project-img"...> with a container div
  perl -0777 -i -pe 's{(<img\b[^>]*class="[^"]*\bproject-img\b[^"]*"[^>]*>)}{<div class="project-img-wrap">$1</div>}g' "$f"

  # Wrap Markdown images with {.project-img} in a Pandoc div
  perl -0777 -i -pe 's{^(.*!\[[^\]]*\]\([^)]+\)\{[^}]*\bproject-img\b[^}]*\}.*)$}{::: {.project-img-wrap}\n$1\n:::}mg' "$f"
done

echo "➜ Ensuring stylesheet and adding non-cropping, large header area…"
mkdir -p styles
touch styles/styles.scss
cp styles/styles.scss "styles/styles.scss.bak.$(date +%s)"

cat >> styles/styles.scss <<'CSS'

/* ===== PROJECT CARD IMAGE: LARGE, UNIFORM, NO-CROP ===== */
.projects-grid .project-card .project-img-wrap {
  width: 100%;
  aspect-ratio: 16/9;              /* adjust to 4/3 or 3/2 if you prefer taller/shorter headers */
  background: rgba(0,0,0,.03);
  border-radius: 12px;
  overflow: hidden;                 /* keeps things tidy if any stray styles remain */
  display: block;
  margin-bottom: 0.5rem;
}

.projects-grid .project-card .project-img-wrap > img.project-img {
  width: 100% !important;
  height: 100% !important;         /* fill the box’s height */
  object-fit: contain !important;  /* show the whole image (no cropping) */
  display: block !important;
  background: transparent;
}

/* Make sure no other rules are shrinking these */
.project-card img.project-img { max-width: none !important; }

/* Optional: card layout polish so text follows nicely */
.project-card {
  display: flex;
  flex-direction: column;
  gap: 0.6rem;
}
CSS

echo "➜ Cleaning build artifacts and launching preview…"
rm -rf _site _freeze || true
quarto preview
