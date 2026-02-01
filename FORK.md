# OpenClaw Fork Maintenance

This repository is a **customized fork** of [openclaw/openclaw](https://github.com/openclaw/openclaw).

## Philosophy

* **Rebase-only workflow**: We mimic a set of patches applied on top of the upstream `main`. changes are replayed on top of upstream updates.
* **Minimal invasion**: We try to keep core logic untouched unless necessary for our specific features.

## Workflow

To update this fork with the latest upstream changes:

```bash
./scripts/sync-fork.sh
```

This script will:

1. Fetch `upstream/main`.
2. Rebase our local `main` on top of `upstream/main`.
3. Reinstall dependencies and rebuild.
4. Run sanity checks.

## Customizations

### Authentication & Identity

* `apps/shared/OpenClawKit/Sources/OpenClawKit/DeviceAuthStore.swift`: Modified to support custom device authentication storage.
* `extensions/google-antigravity-auth`: **[NEW]** Custom authentication extension for Google/Antigravity integration.
* `src/agents/auth-profiles/oauth.ts`: Adjustments for OAuth flow handling specific to our credentials.

### Text-to-Speech (TTS)

* `src/tts/chatterbox.ts`: **[NEW]** Integration with "Chatterbox" local TTS system.
* `src/tts/tts.ts`: Adjusted to route TTS requests to Chatterbox.
* `scripts/chatterbox-server.py`: **[NEW]** Python server for the Chatterbox TTS engine.
* `scripts/test-tts.ts`: **[NEW]** Test script for TTS verification.

### Agent Logic & Memory

* `src/agents/pi-embedded-runner/compact.ts`: Modified to preserve recent messages during compaction.
* `src/agents/pi-embedded-runner/run/attempt.ts`: Modified execution logic for embedded runner.
* `src/auto-reply/reply/memory-flush.ts`: Added `triggerPercent` to control flush thresholds.
* `models_dump.json`: **[NEW]** Local model configuration dump.

### MacOS Configuration

* `apps/macos/Sources/OpenClaw/PeekabooBridgeHostCoordinator.swift`: Changes to the bridge coordinator for the macOS app.

### DevOps & Infrastructure

* `scripts/sync-fork.sh`: **[NEW]** The master sync script for this fork.
* `.agent/workflows/update_openclaw.md`: Workflow documentation for updates.
* `patches/@mariozechner__pi-ai.patch`: **[NEW]** Patch for `pi-ai` dependency.

## Dealing with Conflicts

If `sync-fork.sh` fails during rebase:

1. Fix the conflicts in the files.
2. `git add <file>`
3. `git rebase --continue`
4. If a customization is no longer needed (upstream implemented it), you can `git rebase --skip` our commit.
