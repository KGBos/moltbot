#!/usr/bin/env bash
set -euo pipefail

# Check for local changes and auto-commit
if [[ -n $(git status --porcelain) ]]; then
    echo "==> Unstaged changes detected. Auto-committing..."
    git add .
    
    if [[ -n "${AUTO_COMMIT_MSG:-}" ]]; then
        echo "==> Using provided commit message."
        git commit -m "$AUTO_COMMIT_MSG"
    else
        # If interactive, prompt for message
        if [ -t 0 ]; then
            read -r -p "Enter commit message (default: chore: auto-commit before upstream sync): " user_msg
            if [[ -n "$user_msg" ]]; then
                git commit -m "$user_msg"
            else
                git commit -m "chore: auto-commit before upstream sync"
            fi
        else
            git commit -m "chore: auto-commit before upstream sync"
        fi
    fi
fi

echo "==> Fetching upstream..."
git fetch upstream

echo "==> Updating master (clean upstream mirror)..."
git checkout master
git reset --hard upstream/main
git push origin master --force-with-lease

echo "==> Updating my-patches (rebasing on master)..."
git checkout my-patches
echo "==> Current divergence:"
git rev-list --left-right --count master...my-patches

# Capture current HEAD before rebase for changelog generation
OLD_HEAD=$(git rev-parse HEAD)

echo "==> Rebasing onto master..."
git rebase master

# Push immediately after rebase so remote stays in sync even if builds fail later
echo "==> Syncing my-patches with origin (Force Push)..."
git push origin my-patches --force-with-lease
echo "✅ Origin synced."

# Check if anything actually changed
NEW_HEAD=$(git rev-parse HEAD)
if [ "$OLD_HEAD" == "$NEW_HEAD" ]; then
    echo "✅ Already up to date, no changes to build."
    echo "==> Done!"
    exit 0
fi

# Get list of changed files for conditional builds
CHANGED_FILES=$(git diff --name-only "$OLD_HEAD" HEAD)

# Check what needs rebuilding
NEEDS_DEPS=false
NEEDS_TS_BUILD=false
NEEDS_UI_BUILD=false
NEEDS_MAC_BUILD=false

if echo "$CHANGED_FILES" | grep -qE "^(package\.json|pnpm-lock\.yaml)$"; then
    NEEDS_DEPS=true
fi

if echo "$CHANGED_FILES" | grep -qE "^(src/|packages/|tsconfig)"; then
    NEEDS_TS_BUILD=true
fi

if echo "$CHANGED_FILES" | grep -qE "^ui/"; then
    NEEDS_UI_BUILD=true
fi

if echo "$CHANGED_FILES" | grep -qE "^apps/macos/"; then
    NEEDS_MAC_BUILD=true
fi

echo "==> Changes detected:"
echo "    Dependencies: $NEEDS_DEPS"
echo "    TypeScript:   $NEEDS_TS_BUILD"
echo "    UI:           $NEEDS_UI_BUILD"
echo "    macOS app:    $NEEDS_MAC_BUILD"

# Conditional builds
if [ "$NEEDS_DEPS" = true ]; then
    echo "==> Installing dependencies..."
    pnpm install
else
    echo "==> Skipping dependencies (no package changes)"
fi

if [ "$NEEDS_TS_BUILD" = true ]; then
    echo "==> Building TypeScript..."
    pnpm build
else
    echo "==> Skipping TypeScript build (no src changes)"
fi

if [ "$NEEDS_UI_BUILD" = true ]; then
    echo "==> Building UI..."
    pnpm ui:build
else
    echo "==> Skipping UI build (no ui changes)"
fi

if [ "$NEEDS_MAC_BUILD" = true ]; then
    echo "==> Rebuilding macOS app..."
    ./scripts/restart-mac.sh
    
    echo "==> Checking for Swift 6.2 compatibility issues..."
    if grep -r "FileManager\.default\|Thread\.isMainThread" src/ apps/ --include="*.swift" --quiet; then
        echo "⚠️  Found potential Swift 6.2 deprecated API usage"
        echo "   Run manual fixes or use analyze-mode investigation"
    else
        echo "✅ No obvious Swift deprecation issues found"
    fi
else
    echo "==> Skipping macOS app rebuild (no apps/macos changes)"
fi

echo "==> Verifying gateway health..."
pnpm run openclaw -- health

echo "==> Done!"
echo ""
echo "=== 📝 Changelog vs Previous Version ==="
if [ "$OLD_HEAD" == "$(git rev-parse HEAD)" ]; then
    echo "No changes applied."
else
    # Show concise one-line log of what's new
    git log --no-merges --format="%C(yellow)%h%Creset %s %C(dim white)(%an)%Creset" "$OLD_HEAD..HEAD"
    echo ""
    echo "Total new commits: $(git rev-list --count "$OLD_HEAD..HEAD")"
fi
echo "========================================="
