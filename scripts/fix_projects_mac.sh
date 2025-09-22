#!/usr/bin/env bash
set -euo pipefail

echo "➜ Wrapping project images and applying large no-crop styles (mac-safe)…"

# 1) Wrap <img class="project-img"> in a sizing container (HTML, MD, QMD)
find . -type f \( -name '*.qmd' -o -name '*.md' -o -name '*.html' \) ! -path './_site/*' -print0 \
| while IFS= read -r -d '' f; do
  cp "$f" "$f.bak.$(date +%s)"  # backup
  # Wrap HTML <img ... class="project-img"...>
  perl -0777 -i -pe 's{(?<!project-img-wrap">)(<img\b[^>]*class="[^"]*\bproject-img\b[^"]*"[^>]*>)}{<div class="project-img-wrap">$1</div>}g' "$f"
  # Wrap Markdown image with {.project-img}
  perl -0777 -i -pe 's{^(.*!\[[^\]]*\]\([^)]+\)\{[^}]*\bproject-img\b[^}]*\}.*)$}{::: {.project-img-wrap}\n$1\n:::}mg' "$f"
done

# 2) Ensure stylesheet exists, back it up, and append strong overrides
mkdir -p styles
touch styles/styles.scss
cp styles/styles.scss "styles/styles.scss.bak.$(date +%s)"

cat >> styles/styles.scss <<'CSS'

/* ===== PROJECT CARD IMAGE: BIG, UNIFORM, ZERO-CROP ===== */
.projects-grid .project-card .project-img-wrap {
  width: 100%;
  aspect-ratio: 4/3;               /* <- TALL header area; change to 3/2 for even taller, or 16/9 for wider */
  background: rgba(0,0,0,.03);
  border-radius: 12px;
  overflow: hidden;                 /* tidy edges */
  display: block;
  margin-bottom: 0.6rem;
}

/* Fill the box, but keep whole image visible (no cropping) */
.projects-grid .project-card .project-img-wrap > img.project-img {
  width: 100% !important;
  height: 100% !important;         /* use the box height set by aspect-ratio */
  object-fit: contain !important;  /* NO CROP */
  display: block !important;
  background: transparent;
}

/* Nuke any previous crop/shrink rules that might fight us */
.project-card img.project-img { max-width: none !important; }
.project-card img.project-img, .project-img {
  object-fit: contain !important;
  max-height: none !important;
}
CSS

# 3) Clear build artifacts and relaunch preview
rm -rf _site _freeze || true
echo "➜ Launching Quarto preview…"
quarto preview
