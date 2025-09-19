#!/usr/bin/env bash
set -euo pipefail

echo "➜ Backing up and cleaning current Projects page…"
FILE="./projects.qmd"
if [ -f "$FILE" ]; then
  cp "$FILE" "$FILE.bak.$(date +%s)"
  # remove any junk we previously injected
  sed -i '' '/INJECT_STYLE/d' "$FILE" || true
  sed -i '' -E '/^[[:space:]]*:::/d' "$FILE" || true
  perl -0777 -i -pe 's/<style\b[^>]*>.*?<\/style>\s*//sig' "$FILE" || true
fi

echo "➜ Writing a clean Projects page with real tiles…"
cat > "$FILE" <<'QMD'
---
title: "Projects"
---

<div class="proj-grid" markdown="1">

<div class="proj-card" markdown="1">
![](/assets/projects/raven.jpg){.proj-img}
#### Ecological Diffusion Models & Forecasting
Reaction–diffusion models to predict spread of populations, invasives, and disease. Includes nonlinear/anisotropic diffusion, adaptive monitoring, and links among habitat, movement, and demography. Applications include sea otter recolonization (Alaska) and sage-grouse monitoring (Great Basin).  
**Representative publications:** Williams et al. 2017, 2018; Lu et al. 2020; Eisaguirre et al. 2021; Leach et al. 2022; Eisaguirre et al. 2023a.  
[Publications](/publications.html) • [CV](/cv.pdf)
</div>

<div class="proj-card" markdown="1">
![](/assets/projects/deer.jpg){.proj-img}
#### Wildlife Demography & Harvest Management
Hierarchical demographic models of survival, reproduction, and movement to quantify density dependence, harvest, and environmental change. Case studies include sage-grouse dynamics, cackling goose harvest, and Golden Eagle survival.  
**Representative publications:** Golden et al. (in review); Acevedo et al. (in review); Williams 2015 (PhD); Byrne 2023 (MS); Pacific Flyway Council (2015).  
[Publications](/publications.html) • [CV](/cv.pdf)
</div>

<div class="proj-card" markdown="1">
![](/assets/projects/bear.jpg){.proj-img}
#### Predator–Prey Dynamics & Human–Wildlife Conflict
When predator recovery meets people: sea otters and shellfisheries, ravens with anthropogenic subsidies, and black bear conflict under changing snow and frost regimes. Embeds predator–prey dynamics in diffusion frameworks to inform coexistence and policy.  
**Representative publications:** Shoemaker et al. (in review); Brockman et al. (accepted); Eisaguirre et al. 2023b; Williams et al. 2008.  
[Publications](/publications.html) • [CV](/cv.pdf)
</div>

</div>
QMD

echo "➜ Appending scoped, last-wins CSS for tiles (no global side effects)…"
mkdir -p styles
touch styles/styles.scss
cp styles/styles.scss "styles/styles.scss.bak.$(date +%s)"

cat >> styles/styles.scss <<'CSS'

/* ===== PROJECT TILES (scoped .proj-* only) ===== */
.proj-grid{
  display:grid; gap:1.25rem;
  grid-template-columns:repeat(auto-fit,minmax(360px,1fr));
  align-items:stretch;
}
.proj-card{
  display:flex; flex-direction:column; gap:.7rem;
  padding:1rem; background:#f7efe5; border-radius:16px;
  box-shadow:0 2px 8px rgba(0,0,0,.06); height:100%;
}
.proj-img{
  width:100%; aspect-ratio:3/2; /* uniform tile header */
  object-fit:contain;           /* show the whole image (no crop) */
  background:rgba(0,0,0,.04);
  border-radius:12px; display:block;
}
.proj-card h4{ margin:.6rem 0 .25rem; }
.proj-card p{ margin:0; }
CSS

echo "➜ Clearing build artifacts and launching preview…"
rm -rf _site _freeze || true
quarto preview
