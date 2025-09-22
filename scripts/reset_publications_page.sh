#!/usr/bin/env bash
set -euo pipefail

# 1) Make/backup a BibTeX file (the page will render whatever is in here)
if [ ! -f publications.bib ]; then
  cat > publications.bib <<'BIB'
% Put your BibTeX here (export from Google Scholar, Zotero, Mendeley, etc.)
% Example:
% @article{williams2018diffusion,
%   author = {Williams, Perry J. and ...},
%   title  = {Ecological diffusion ...},
%   journal= {...},
%   year   = {2018},
%   doi    = {...}
% }
BIB
  echo "➜ Created publications.bib (empty placeholder). Paste your BibTeX into it after this runs."
fi

# 2) Write a clean publications.qmd (prints the whole bib where we put the #refs div)
cp -f publications.qmd "publications.qmd.bak.$(date +%s)" 2>/dev/null || true
cat > publications.qmd <<'QMD'
---
title: "Publications"
page-layout: full
bibliography: publications.bib
nocite: |
  @*
format:
  html:
    link-citations: true
---

# Publications

<!-- The bibliography will be injected right here -->
::: {#refs}
:::

## In review / revision
<!-- Keep this simple and hand-edited. Example entries: -->
<!-- - Golden, J.E., Barnes, J.G., Williams, P.J. (in review). Estimating Survival and Population Trajectories of Golden Eagles. -->
<!-- - Acevedo, A. et al. (in revision). Spatio-temporal drivers of sage-grouse population change. -->
QMD

# 3) Add a touch of styling (optional, scoped and safe)
mkdir -p styles
touch styles/styles.scss
cp "styles/styles.scss" "styles/styles.scss.bak.$(date +%s)" 2>/dev/null || true

# Add only once
if ! grep -q "/* PUBLICATIONS PAGE TWEAKS */" styles/styles.scss; then
cat >> styles/styles.scss <<'CSS'

/* PUBLICATIONS PAGE TWEAKS */
#refs {
  line-height: 1.4;
}
#refs .csl-entry {
  margin-bottom: 0.6rem;
}
#quarto-document-content h1, 
#quarto-document-content h2 {
  scroll-margin-top: 80px;
}
CSS
fi

# 4) Clean build artifacts and preview
rm -rf _site _freeze 2>/dev/null || true
echo "➜ Launching Quarto preview… (Shift+Reload in the browser)"
quarto preview
