#!/usr/bin/env bash
set -euo pipefail

IMG_PATH="assets/perry_2024.jpg"

# 0) Verify the image exists
[ -f "$IMG_PATH" ] || { echo "✗ Missing $IMG_PATH"; exit 1; }

# 1) Find the About page (prefer about.qmd; else any *about*.qmd; else index.qmd)
FILE=""
if [ -f "./about.qmd" ]; then
  FILE="./about.qmd"
else
  FILE="$(find . -type f -name '*about*.qmd' ! -path './_site/*' | head -n 1 || true)"
  [ -n "$FILE" ] || { [ -f "./index.qmd" ] && FILE="./index.qmd"; }
fi
[ -n "$FILE" ] && [ -f "$FILE" ] || { echo "✗ Could not find about.qmd or index.qmd"; exit 1; }

echo "→ Using About page: $FILE"
cp "$FILE" "$FILE.bak.$(date +%s)"

# 2) Skip if already inserted
if grep -qE '\.about-photo' "$FILE"; then
  echo "✓ Photo already referenced in $FILE — skipping insert."
else
  # Insert image markdown right after YAML front matter (or at top if none)
  perl -0777 -i -pe '
    my $img = qq{\n![Perry Williams]('"$IMG_PATH"'){.about-photo}\n\n};
    if (m/\A---\s*\n.*?\n---\s*\n/s) { s/\A(---\s*\n.*?\n---\s*\n)/$1.$img/s; }
    else { $_ = $img . $_; }
  ' "$FILE"
  echo "✓ Inserted photo markdown into $FILE"
fi

# 3) Add scoped CSS so the headshot looks right (overrides any old global img rules)
mkdir -p styles
touch styles/styles.scss
cp styles/styles.scss "styles/styles.scss.bak.$(date +%s)"

if ! grep -q "/* ABOUT PHOTO STYLES */" styles/styles.scss 2>/dev/null; then
cat >> styles/styles.scss <<'CSS'

/* ABOUT PHOTO STYLES */
#quarto-document-content img.about-photo{
  width: 260px !important;
  max-width: 40% !important;
  height: auto !important;        /* beat any earlier fixed/clamped heights */
  object-fit: cover !important;   /* normal headshot look */
  border-radius: 9999px;          /* round/circle */
  float: right;
  margin: 0 0 0.75rem 1rem;
  box-shadow: 0 2px 8px rgba(0,0,0,.08);
}

/* Stack nicely on small screens */
@media (max-width: 700px){
  #quarto-document-content img.about-photo{
    float: none;
    display: block;
    margin: 0 auto 0.75rem auto;
    width: 200px !important;
    max-width: 70% !important;
  }
}
CSS
  echo "✓ Added about photo styles to styles/styles.scss"
fi

# 4) Rebuild preview
rm -rf _site _freeze 2>/dev/null || true
echo "➜ Launching Quarto preview… (Shift+Reload in browser)"
quarto preview
