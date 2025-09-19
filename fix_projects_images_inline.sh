#!/usr/bin/env bash
set -euo pipefail

echo "➜ Looking for your Projects source file…"

# Find likely Projects source files (don’t touch generated _site)
FOUND=""
for pat in '*projects*.qmd' '*project*.qmd' 'projects.qmd' 'projects.md' '*projects*.md' ; do
  while IFS= read -r f; do
    FOUND="${FOUND}
${f}"
  done < <(find . -type f -name "$pat" ! -path "./_site/*" 2>/dev/null || true)
done

# Trim
FOUND="$(echo "$FOUND" | sed '/^\s*$/d' || true)"

if [ -z "$FOUND" ]; then
  echo "✗ Could not find a Projects .qmd/.md file. Rename your file to include 'projects' and rerun."
  exit 1
fi

# Build the style block we’ll inject (BIG images, no crop; modest grid widening)
cat > /tmp/__proj_style__.html <<'CSS'
<style>
/* === FORCE BIG PROJECT IMAGES (in-page, last-wins) === */

/* Make ALL images in main content BIG and not cropped */
#quarto-document-content img {
  display: block !important;
  width: 100% !important;
  height: clamp(520px, 40vw, 920px) !important; /* <-- BIG visible height */
  object-fit: contain !important;               /* show entire image; no cropping */
  max-width: none !important;
  max-height: none !important;
  border-radius: 14px;
  background: rgba(0,0,0,.04);
}

/* If a DIV with background-image is used instead of <img> */
#quarto-document-content [style*="background-image"],
#quarto-document-content .project-img {
  width: 100% !important;
  min-height: clamp(520px, 40vw, 920px) !important;
  background-size: contain !important;
  background-position: center !important;
  background-repeat: no-repeat !important;
  border-radius: 14px;
}

/* Give common project grids some room so images aren't cramped */
#quarto-document-content .projects-grid,
#quarto-document-content .project-grid,
#quarto-document-content .cards-grid,
#quarto-document-content .quarto-grid {
  display: grid;
  gap: 1.25rem;
  grid-template-columns: repeat(2, minmax(0, 1fr));
}
@media (min-width: 1600px) {
  #quarto-document-content .projects-grid,
  #quarto-document-content .project-grid,
  #quarto-document-content .cards-grid,
  #quarto-document-content .quarto-grid {
    grid-template-columns: repeat(3, minmax(0, 1fr));
  }
}
</style>
CSS

echo "➜ Injecting inline style into Projects page(s)…"

while IFS= read -r FILE; do
  [ -z "$FILE" ] && continue
  echo "→ Patching $FILE"
  cp "$FILE" "$FILE.bak.$(date +%s)"

  # Insert after YAML front matter if present; else prepend.
  # BSD-safe Perl: read entire file, then replace or prepend.
  perl -0777 -i -pe '
    BEGIN {
      local $/;
      open my $S, q{<}, q{/tmp/__proj_style__.html} or die $!;
      our $STYLE = <$S>;
      close $S;
    }
    if (m/\A---\s*\n.*?\n---\s*\n/s) {
      s/\A(---\s*\n.*?\n---\s*\n)/$1.$STYLE/se;
    } else {
      $_ = $STYLE . "\n" . $_;
    }
  ' "$FILE"

done <<EOF2
$FOUND
EOF2

echo "➜ Rebuilding preview…"
rm -rf _site _freeze || true
quarto preview
