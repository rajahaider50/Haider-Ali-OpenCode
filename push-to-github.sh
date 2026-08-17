#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/rajahaider50/Haider-Ali-OpenCode.git"
BRANCH="main"

echo "=============================================="
echo " HAIDER ALI — GITHUB PUSH SCRIPT"
echo "=============================================="
echo ""

cd "$(dirname "$0")"

if [ ! -d ".git" ]; then
  echo "[ERROR] Not a git repository."
  exit 1
fi

CURRENT=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)
if [ "$CURRENT" != "$BRANCH" ]; then
  echo "[INFO] Switching to branch $BRANCH..."
  git branch -M "$BRANCH" 2>/dev/null || true
fi

git remote set-url origin "$REPO_URL" 2>/dev/null || git remote add origin "$REPO_URL"

echo "[INFO] Pushing to $REPO_URL ..."
echo "[INFO] You will be prompted for your GitHub username and token."
echo ""

git push -u origin "$BRANCH"

echo ""
echo "=============================================="
echo " PUSH COMPLETE"
echo "=============================================="
echo " Repository: $REPO_URL"
echo " Branch:     $BRANCH"
echo "=============================================="
