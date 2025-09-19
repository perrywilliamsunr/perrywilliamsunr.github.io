#!/usr/bin/env bash
set -euo pipefail

# 0) Basic git sanity
if [ ! -d .git ]; then
  echo "→ Initializing git repo"
  git init
  git checkout -b main || git branch -m main || true
fi

# 1) Create GitHub Actions workflow for Quarto → Pages
echo "→ Writing .github/workflows/quarto-pages.yml"
mkdir -p .github/workflows

cat > .github/workflows/quarto-pages.yml <<'YML'
name: Quarto to GitHub Pages

on:
  push:
    branches: ["main"]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: "pages"
  cancel-in-progress: true

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Configure Pages
        uses: actions/configure-pages@v5

      - name: Setup Quarto
        uses: quarto-dev/quarto-actions/setup@v2
        with:
          # set to 'true' if you need LaTeX/PDF rendering:
          tinytex: false

      # (Optional) If your site uses Python/R, set up here.
      # - uses: actions/setup-python@v5
      #   with: { python-version: "3.11" }
      # - uses: r-lib/actions/setup-r@v2

      - name: Render site
        run: quarto render

      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: _site

  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    needs: build
    steps:
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
YML

# 2) Commit and push
echo "→ Committing workflow and site files"
git add -A
git commit -m "ci: publish Quarto site to GitHub Pages via Actions" || echo "✓ Nothing to commit; continuing"

# Try to push; set upstream if needed
if git rev-parse --abbrev-ref --symbolic-full-name @{u} >/dev/null 2>&1; then
  git push
else
  # Try common remotes; if none, print instructions
  if git remote | grep -q '^origin$'; then
    git push -u origin main
  else
    echo "✗ No git remote configured."
    echo "  Add one, then re-run this script. Example:"
    echo "    git remote add origin git@github.com:YOURUSER/YOURREPO.git"
    echo "    git push -u origin main"
    exit 1
  fi
fi

# 3) Print the expected Pages URL from the remote
REMOTE_URL="$(git remote get-url origin 2>/dev/null || true)"
if [ -n "$REMOTE_URL" ]; then
  # Parse user/repo from https or ssh style
  case "$REMOTE_URL" in
    https://github.com/*/*.git) slug="${REMOTE_URL#https://github.com/}"; slug="${slug%.git}" ;;
    https://github.com/*/*)     slug="${REMOTE_URL#https://github.com/}" ;;
    git@github.com:*/*.git)     slug="${REMOTE_URL#git@github.com:}"; slug="${slug%.git}" ;;
    git@github.com:*/*)         slug="${REMOTE_URL#git@github.com:}" ;;
    *) slug="" ;;
  esac
  if [ -n "$slug" ]; then
    USER="${slug%%/*}"
    REPO="${slug##*/}"
    if [ "$REPO" = "${USER}.github.io" ]; then
      URL="https://${USER}.github.io/"
    else
      URL="https://${USER}.github.io/${REPO}/"
    fi
    echo "→ GitHub Actions will build & deploy to Pages."
    echo "  When the action is green, your site will be at:"
    echo "  $URL"
    echo "  (Actions tab → 'Quarto to GitHub Pages' should show the deploy.)"
  fi
fi
