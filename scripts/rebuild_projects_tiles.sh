#!/usr/bin/env bash
set -euo pipefail

# ---- 0) Locate the 5 images (png) ----
find_img() {
  # search common asset dirs for a name (case-insensitive)
  local name="$1"
  find assets images img static -type f -iname "${name}.png" 2>/dev/null | head -n 1
}
DIFF="$(find_img diffusion || true)";      DIFF="${DIFF#./}"
DEMOG="$(find_img demography || true)";    DEMOG="${DEMOG#./}"
MOVE="$(find_img movement || true)";       MOVE="${MOVE#./}"
PRED="$(find_img 'predator-prey' || true)";PRED="${PRED#./}"
TOOLS="$(find_img tools || true)";         TOOLS="${TOOLS#./}"

missing=()
[ -n "$DIFF" ]  || missing+=("diffusion.png")
[ -n "$DEMOG" ] || missing+=("demography.png")
[ -n "$MOVE" ]  || missing+=("movement.png")
[ -n "$PRED" ]  || missing+=("predator-prey.png")
[ -n "$TOOLS" ] || missing+=("tools.png")

if [ "${#missing[@]}" -gt 0 ]; then
  echo "✗ Missing file(s): ${missing[*]}"
  echo "   Put them under assets/ or images/ (e.g., assets/projects/) and rerun."
  exit 1
fi

echo "✓ Using:"
printf "   diffusion → %s\n   demography → %s\n   movement → %s\n   predator-prey → %s\n   tools → %s\n" "$DIFF" "$DEMOG" "$MOVE" "$PRED" "$TOOLS"

# ---- 1) Pick projects file; default to ./projects.qmd or first *projects*.qmd ----
FILE="./projects.qmd"
if [ ! -f "$FILE" ]; then
  FILE="$(find . -type f -name '*projects*.qmd' ! -path './_site/*' | head -n 1 || true)"
fi
[ -n "$FILE" ] && [ -f "$FILE" ] || { echo "✗ Could not find projects.qmd"; exit 1; }

echo "→ Rebuilding $FILE"
cp "$FILE" "$FILE.bak.$(date +%s)"

# Clean junk we may have injected before
#  - remove INJECT_STYLE lines
#  - remove bare fenced-div lines starting with :::
#  - strip any inline <style>…</style> blocks
sed -i '' '/INJECT_STYLE/d' "$FILE" || true
sed -i '' -E '/^[[:space:]]*:::/d' "$FILE" || true
perl -0777 -i -pe 's/<style\b[^>]*>.*?<\/style>\s*//sig' "$FILE" || true

# ---- 2) Replace file with clean 5-tile markup (scoped classes) ----
cat > "$FILE" <<QMD
---
title: "Projects"
---

<div class="proj-grid" markdown="1">

<div class="proj-card" markdown="1">
![]($DIFF){.proj-img}
#### Ecological Diffusion Models & Forecasting
Reaction–diffusion models to predict spread of populations, invasives, and disease. Includes nonlinear/anisotropic diffusion, adaptive monitoring, and links among habitat, movement, and demography. Applications include sea otter recolonization (Alaska) and sage-grouse monitoring (Great Basin).  
**Representative publications:** Williams et al. 2017, 2018; Lu et al. 2020; Eisaguirre et al. 2021; Leach et al. 2022; Eisaguirre et al. 2023a.  
[Publications](/publications.html) • [CV](/cv.pdf)
</div>

<div class="proj-card" markdown="1">
![]($DEMOG){.proj-img}
#### Wildlife Demography & Harvest Management
Hierarchical demographic models of survival, reproduction, and movement to quantify density dependence, harvest, and environmental change. Case studies include sage-grouse dynamics, cackling goose harvest, and Golden Eagle survival.  
**Representative publications:** Golden et al. (in review); Acevedo et al. (in review); Williams 2015 (PhD); Byrne 2023 (MS); Pacific Flyway Council (2015).  
[Publications](/publications.html) • [CV](/cv.pdf)
</div>

<div class="proj-card" markdown="1">
![]($PRED){.proj-img}
#### Predator–Prey Dynamics & Human–Wildlife Conflict
Sea otters and shellfisheries, ravens with anthropogenic subsidies, and black bear conflict under changing snow and frost regimes. Embeds predator–prey dynamics in diffusion frameworks to inform coexistence and policy.  
**Representative publications:** Shoemaker et al. (in review); Brockman et al. (accepted); Eisaguirre et al. 2023b; Williams et al. 2008.  
[Publications](/publications.html) • [CV](/cv.pdf)
</div>

<div class="proj-card" markdown="1">
![]($MOVE){.proj-img}
#### Integrating Movement Ecology Across Scales
Links individual-level telemetry with population-level dynamics to bridge fine-scale behavior and range dynamics; connects step-selection, state-space, and mechanistic diffusion models.  
**Representative publications:** Eisaguirre et al. 2025; Eisaguirre, Williams & Hooten 2024; Keating 2021 (MS).  
[Publications](/publications.html) • [CV](/cv.pdf)
</div>

<div class="proj-card" markdown="1">
![]($TOOLS){.proj-img}
#### Statistical & Computational Tools for Ecology
Bayesian model selection, hierarchical abundance/survival models, and open-source software and training that disseminate quantitative tools for ecology.  
**Representative publications:** Blume et al. 2024; Gerber & Williams 2020; Womble et al. 2017.  
[Publications](/publications.html) • [CV](/cv.pdf)
</div>

</div>
QMD

# ---- 3) Scoped, last-wins CSS (overrides any prior global hacks) ----
mkdir -p styles
touch styles/styles.scss
cp styles/styles.scss "styles/styles.scss.bak.$(date +%s)"

cat >> styles/styles.scss <<'CSS'

/* ===== PROJECT TILES (.proj-*) — BIG, UNIFORM, NO CROP ===== */
.proj-grid{
  display:grid !important;
  gap:1.25rem !important;
  grid-template-columns:repeat(auto-fit,minmax(360px,1fr)) !important;
  align-items:stretch !important;
}
.proj-card{
  display:flex !important; flex-direction:column !important; gap:.7rem !important;
  padding:1rem !important; background:#f7efe5 !important; border-radius:16px !important;
  box-shadow:0 2px 8px rgba(0,0,0,.06) !important; height:100% !important;
}
/* Override any earlier #quarto-document-content img rules */
#quarto-document-content img.proj-img{
  width:100% !important;
  aspect-ratio:3/2 !important;      /* uniform tile header size */
  height:auto !important;
  object-fit:contain !important;     /* show full image (no cropping) */
  background:rgba(0,0,0,.04) !important;
  border-radius:12px !important;
  display:block !important;
}
.proj-card h4{ margin:.6rem 0 .25rem; }
.proj-card p{ margin:0; }
CSS

# ---- 4) Rebuild ----
rm -rf _site _freeze || true
echo "→ Launching preview… (Shift+Reload in browser)"
quarto preview
