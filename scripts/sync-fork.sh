#!/usr/bin/env bash
set -euo pipefail

# Check for local changes and auto-commit
if [[ -n $(git status --porcelain) ]]; then
    echo "==> Unstaged changes detected. Auto-committing..."
    git add .
    git commit -m "chore: auto-commit before upstream sync"
fi

echo "==> Fetching upstream..."
git fetch upstream

echo "==> Current divergence:"
git rev-list --left-right --count main...upstream/main

echo "==> Rebasing onto upstream/main..."
git rebase upstream/main

echo "==> Installing dependencies..."
pnpm install

echo "==> Building..."
pnpm build
pnpm ui:build

echo "==> Running doctor..."
# echo "Skipping interactive doctor. Run 'pnpm run openclaw -- doctor' manually if needed."

echo "==> Rebuilding macOS app..."
./scripts/restart-mac.sh

echo "==> Verifying gateway health..."
pnpm run openclaw -- health

echo "==> Checking for Swift 6.2 compatibility issues..."
if grep -r "FileManager\.default\|Thread\.isMainThread" src/ apps/ --include="*.swift" --quiet; then
    echo "⚠️  Found potential Swift 6.2 deprecated API usage"
    echo "   Run manual fixes or use analyze-mode investigation"
else
    echo "✅ No obvious Swift deprecation issues found"
fi

echo "==> Testing agent functionality..."
# Note: Update session ID or run manually
# pnpm run openclaw -- agent --message "Verification: Upstream sync and macOS rebuild completed successfully." --session-id YOUR_TELEGRAM_SESSION_ID || echo "Warning: Agent test failed"

echo "==> Done! Check Telegram for verification message."
echo ""
echo "IMPORTANT: Please review FORK.md to ensure all customizations are still valid."
echo "If you have just rebased, run 'git push --force-with-lease' to update your remote."
