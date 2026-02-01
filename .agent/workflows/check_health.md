---
description: Check OpenClaw System Health
---

This workflow runs a series of commands to check the health and status of the OpenClaw system, including presence, heartbeat, channel connectivity, and a comprehensive doctor check with deep scanning.

// turbo-all

1. OpenClaw Doctor Check (Deep)
   `node openclaw.mjs doctor --deep --non-interactive`

2. Check system presence
   `node openclaw.mjs system presence`

3. Check last heartbeat
   `node openclaw.mjs system heartbeat last`

4. Check channels status (Deep Probe)
   `node openclaw.mjs channels status --probe`
