#!/usr/bin/env bash
set -euo pipefail

echo "➜ Making project images BIG on the Projects page…"

# 1) Build the style block we will inject inline on the Projects page
STYLE_FILE="$(mktemp -t projstyle.XXXXXX)"
cat > "$STYLE_FILE" <<'CSS'
<style>
/* === Force BIG images on Projects page === */
/* Make main content wider so cards/images can actually grow */
:root { --content-max-width: 1400px; }

/* If a grid exists for projects, make it roomy (2–3 columns, not skinny) */
#quarto-document-content .projects-grid,
#quarto-document-content .project-grid,
#quarto-document-content .cards-grid,
#quarto-document-content .quarto-grid,
#quarto-document-content .grid {
  display: grid;
  gap: 1.25rem;
  grid-template-columns: repeat(2, minmax(0, 1fr));
}
@media (min-width: 1600px) {
  #quarto-document-content .projects-grid,
  #quarto-document-content .project-grid,
  #quarto-document-content .cards-grid,
  #quarto-document-content .quarto-grid,
  #quarto-document-content .grid {
    grid-template-columns: repeat(3, minmax(0, 1fr));
  }
}

/* Make ALL images on this page BIG. (Yes, this is broad on purpose.) */
#quarto-document-content img {
  display: block !important;
  width: 100% !important;
  height: clamp(480px, 40vw, 900px) !important; /* <-- BIG visible height */
  object-fit: contain !important;               /* no cropping; full image shows */
  max-width: none !important;
  max-height: none !important;
  border-radius: 14px;
  background: rgba(0,0,0,.03);
}

/* If you used a DIV with background-image instead of <img> */
#quarto-document-content [style*="background-image"],
#quarto-document-content .project-img {
  width: 100% !important;
  min-height: clamp(480px, 40vw, 900px) !important;
  background-size: contain !important;
  background-position: center !important;
  background-repeat: no-repeat !important;
  border-radius: 14px;
}
</style>
CSS

# 2) Find Projects source files (don’t touch generated _site)
FOUND_FILES=""
# Prefer obvious names
for pat in '*projects*.qmd' '*project*.qmd' 'projects.qmd' 'projects.md' '*projects*.md' ; do
  for f in $(find . -type f -name "$pat" ! -path "./_site/*" 2>/dev/null); do
    FOUND_FILES="${FOUND_FILES}
${f}"
  done
done
# If still empty, try titles that say "Projects"
if [ -z "$(echo "$FOUND_FILES" | tr -d ' \n')" ]; then
  while IFS= read -r f; do
    FOUND_FILES="${FOUND_FILES}
${f}"
  done < <(grep -RIl --include='*.qmd' '^title:.*[Pp]roject' . 2>/dev/null || true)
fi

# Trim whitespace
FOUND_FILES="$(echo "$FOUND_FILES" | sed '/^\s*$/d')"

if [ -z "$FOUND_FILES" ]; then
  echo "✗ Could not find a Projects .qmd/.md file. If your file has a different name, run again after renaming it to include 'projects'."
  exit 1
fi

# 3) Inject the style block *after* YAML front matter if present; otherwise prepend it
inject_style() {
  local file="$1"
  echo "→ Patching $file"
  cp "$file" "$file.bak.$(date +%s)"

  # Detect end of YAML front matter (second '---' from top)
  if head -n1 "$file" | grep -q '^---\s*$'; then
    END_LINE="$(awk 'NR==1 && /^---[[:space:]]*$/ {in=1; next} in && /^---[[:space:]]*$/ {print NR; exit} {next}' "$file")"
    if [ -n "$END_LINE" ]; then
      # Write: up to END_LINE, then style, then the rest
      awk -v end="$END_LINE" -v sfile="$STYLE_FILE" 'NR==end{print; while((getline l < sfile)>0) print l; close(sfile); next} {print}' "$file" > "$file.tmp"
      mv "$file.tmp" "$file"
      return
    fi
  fi

  # No YAML front matter; prepend style
  cat "$STYLE_FILE" "$file" > "$file.tmp" && mv "$file.tmp" "$file"
}

# Patch each found file
while IFS= read -r f; do
  [ -z "$f" ] && continue
  inject_style "$f"
done <<EOF2
$FOUND_FILES
EOF2

# 4) Rebuild preview cleanly
rm -rf _site _freeze || true
echo "➜ Launching Quarto preview… (Shift+Reload in browser)"
quarto preview
