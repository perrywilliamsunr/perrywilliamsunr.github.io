#!/usr/bin/env bash
set -euo pipefail

echo "➜ Backing up and appending last-wins overrides…"
mkdir -p styles
touch styles/styles.scss
cp styles/styles.scss "styles/styles.scss.bak.$(date +%s)"

cat >> styles/styles.scss <<'CSS'
/* ===================== BOMBPROOF PROJECTS OVERRIDES (LAST WINS) ===================== */

/* 1) Make the page content wide so cards/images can actually be large */
:root {
  /* Quarto respects this variable for main content width */
  --content-max-width: 1400px;   /* bump if you want even wider, e.g., 1600px */
}

/* 2) If the Projects layout uses Bootstrap rows/cols, make those rows render 2–3 BIG columns
      whenever they contain a .project-card (supported in modern Chrome/Safari/Firefox). */
main .row:has(.project-card) {
  display: flex !important;
  flex-wrap: wrap !important;
  gap: 1.25rem;
}
main .row:has(.project-card) > [class*="col"] {
  flex: 0 0 48% !important;   /* ~2 columns on desktop */
  max-width: 48% !important;
}
@media (min-width: 1600px) {
  main .row:has(.project-card) > [class*="col"] {
    flex: 0 0 31.5% !important;  /* ~3 columns on very wide screens */
    max-width: 31.5% !important;
  }
}

/* 3) If you used a custom grid (.projects-grid / .project-grid), make those big too */
.projects-grid, .project-grid, .cards-grid, .quarto-grid {
  display: grid !important;
  gap: 1.25rem !important;
  grid-template-columns: repeat(2, minmax(0, 1fr)) !important; /* 2 columns by default */
}
@media (min-width: 1600px) {
  .projects-grid, .project-grid, .cards-grid, .quarto-grid {
    grid-template-columns: repeat(3, minmax(0, 1fr)) !important; /* 3 columns wide screens */
  }
}

/* 4) FORCE images in project cards to be BIG and NEVER CROPPED */
.projects-grid .project-card img,
.project-grid  .project-card img,
.cards-grid    .project-card img,
.quarto-grid   .card img,
main .row:has(.project-card) .project-card img,
.project-card img.project-img,
.project-card picture img {
  display: block !important;
  width: 100% !important;
  height: clamp(440px, 36vw, 820px) !important;  /* BIG visible area */
  max-width: none !important;
  max-height: none !important;
  object-fit: contain !important;                /* show entire image */
  border-radius: 14px !important;
  background: rgba(0,0,0,.03) !important;
}

/* 5) If “images” are DIVs with CSS backgrounds, make those big & non-cropping too */
.project-card .project-img,
.projects-grid .project-img,
.project-grid  .project-img,
.cards-grid    .project-img {
  width: 100% !important;
  min-height: clamp(440px, 36vw, 820px) !important;
  background-size: contain !important;
  background-position: center !important;
  background-repeat: no-repeat !important;
  border-radius: 14px !important;
}

/* 6) Belt & suspenders: prevent upstream rules from clipping */
.project-card, .project-card * {
  max-height: none !important;
  overflow: visible !important;
}
CSS

echo "➜ Clearing old builds and launching preview…"
rm -rf _site _freeze || true
quarto preview
