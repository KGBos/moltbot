---
description: Check & Fix OpenClaw System Health
---

# System Health Check

This workflow runs a comprehensive suite of tools to diagnose and fix OpenClaw system health.

// turbo-all

1. OpenClaw Doctor (Deep Scan & Auto-Fix)
   `node openclaw.mjs doctor --deep --fix --non-interactive`

2. Security Audit
   `node openclaw.mjs security audit`

3. System Status (Deep Probe)
   `node openclaw.mjs status --deep`

4. Validate Configuration
   `node openclaw.mjs --version`

5. Check Memory Index
   `node openclaw.mjs memory status`
