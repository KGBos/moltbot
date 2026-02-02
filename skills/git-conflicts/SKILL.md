---
name: git-conflicts
description: Detect and resolve git merge/rebase conflicts. Use when a rebase or merge fails with conflicts, or when asked to sync a fork.
---

# Git Conflict Resolution

## When to Use

- `git rebase` or `git merge` exits with conflicts
- You see `CONFLICT (content)` in output
- User asks you to sync or update a fork

## Detecting Conflicts

```bash
# Check if in conflicted state
git status
# Look for: "You have unmerged paths" or "Unmerged paths:"
```

## Reading Conflicted Files

Conflict markers look like:

```
<<<<<<< HEAD
your local changes
=======
upstream changes
>>>>>>> upstream/main
```

## Resolution Strategy

1. **Read the conflicted file** to understand both versions
2. **Decide resolution**:
   - If upstream is clearly better → keep upstream
   - If local is a customization you need → keep local
   - If both have value → merge manually
3. **Edit the file** to remove conflict markers and keep the correct content
4. **Stage and continue**:

   ```bash
   git add <resolved-file>
   git rebase --continue  # or git merge --continue
   ```

## Common Patterns

### package.json / pnpm-lock.yaml

Usually take upstream, then run `pnpm install` to regenerate lock.

```bash
git checkout --theirs package.json pnpm-lock.yaml
git add package.json pnpm-lock.yaml
```

### Configuration files (tsconfig, etc.)

Compare carefully. Upstream may have new required fields.

### Source files

Read both versions. If your local change was a bug fix that's now in upstream, skip your commit:

```bash
git rebase --skip
```

## Aborting

If conflicts are too complex:

```bash
git rebase --abort  # or git merge --abort
```

Then notify the user that manual intervention is needed.

## Safety Rules

1. **Never force-resolve** files you don't understand
2. **Always run tests** after resolving if available
3. **Notify the user** if you're unsure about a resolution
4. **Abort and report** rather than making wrong choices
