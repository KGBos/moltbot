#!/usr/bin/env bash
# Safe upstream sync for agent heartbeats
# Handles conflicts gracefully and notifies on issues

set -euo pipefail

REPO_DIR="/Users/leon/code/forks/openclaw"
cd "$REPO_DIR"

# Check for local changes
if [[ -n $(git status --porcelain) ]]; then
    echo "SYNC_STATUS: dirty"
    echo "Uncommitted changes detected. Auto-committing..."
    git add .
    git commit -m "chore: auto-commit before upstream sync"
fi

# Fetch upstream
git fetch upstream 2>/dev/null || {
    echo "SYNC_STATUS: fetch_failed"
    echo "Failed to fetch upstream"
    exit 1
}

# Check divergence
AHEAD=$(git rev-list --count upstream/main..main)
BEHIND=$(git rev-list --count main..upstream/main)

echo "SYNC_DIVERGENCE: ahead=$AHEAD behind=$BEHIND"

if [ "$BEHIND" -eq 0 ]; then
    echo "SYNC_STATUS: up_to_date"
    echo "Already up to date with upstream."
    exit 0
fi

echo "SYNC_STATUS: updating"
echo "Found $BEHIND upstream commits to apply..."

# Save current HEAD for rollback
OLD_HEAD=$(git rev-parse HEAD)

# Attempt rebase
if ! git rebase upstream/main 2>&1; then
    # Rebase failed - likely conflicts
    CONFLICTED_FILES=$(git diff --name-only --diff-filter=U 2>/dev/null || echo "")
    
    if [ -n "$CONFLICTED_FILES" ]; then
        echo "SYNC_STATUS: conflict"
        echo "SYNC_ACTION: notify_user"
        echo ""
        echo "⚠️  CONFLICTS DETECTED - USER NOTIFICATION REQUIRED"
        echo ""
        echo "The following files have conflicts:"
        echo "$CONFLICTED_FILES"
        echo ""
        echo "Upstream has changes that conflict with your local fork."
        echo "Aborting rebase to preserve your current state."
        echo ""
        echo "OPTIONS:"
        echo "1. Ask me (your agent) to resolve the conflicts"
        echo "2. Run ./scripts/sync-fork.sh manually with assistance"
        echo "3. Wait for the next sync attempt"
        echo ""
        git rebase --abort
        exit 1
    else
        echo "SYNC_STATUS: rebase_failed"
        echo "Rebase failed for unknown reason"
        git rebase --abort 2>/dev/null || true
        exit 1
    fi
fi

# Push to origin
echo "Pushing to origin..."
git push origin main --force-with-lease || {
    echo "SYNC_STATUS: push_failed"
    exit 1
}

# Check what needs rebuilding
CHANGED_FILES=$(git diff --name-only "$OLD_HEAD" HEAD)

NEEDS_DEPS=false
NEEDS_TS_BUILD=false
NEEDS_UI_BUILD=false
NEEDS_MAC_BUILD=false

echo "$CHANGED_FILES" | grep -qE "^(package\.json|pnpm-lock\.yaml)$" && NEEDS_DEPS=true
echo "$CHANGED_FILES" | grep -qE "^(src/|packages/|tsconfig)" && NEEDS_TS_BUILD=true
echo "$CHANGED_FILES" | grep -qE "^ui/" && NEEDS_UI_BUILD=true
echo "$CHANGED_FILES" | grep -qE "^apps/macos/" && NEEDS_MAC_BUILD=true

# Conditional builds
[ "$NEEDS_DEPS" = true ] && pnpm install
[ "$NEEDS_TS_BUILD" = true ] && pnpm build
[ "$NEEDS_UI_BUILD" = true ] && pnpm ui:build

# macOS rebuild is optional on heartbeat - can skip for speed
if [ "$NEEDS_MAC_BUILD" = true ]; then
    echo "SYNC_STATUS: mac_rebuild_needed"
    echo "macOS app changes detected. Run ./scripts/restart-mac.sh manually."
else
    echo "SYNC_STATUS: success"
fi

echo "SYNC_COMMITS_APPLIED: $(git rev-list --count "$OLD_HEAD..HEAD")"
