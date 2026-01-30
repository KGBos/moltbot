---
description: 
---

### 1. Telegram Account Discovery

**File:** [accounts.ts](file:///Users/leon/code/forks/openclaw/src/telegram/accounts.ts)

```diff
 export function listTelegramAccountIds(cfg: OpenClawConfig): string[] {
-  const ids = Array.from(
-    new Set([...listConfiguredAccountIds(cfg), ...listBoundAccountIds(cfg, "telegram")]),
-  );
-  debugAccounts("listTelegramAccountIds", ids);
-  if (ids.length === 0) return [DEFAULT_ACCOUNT_ID];
-  return ids.sort((a, b) => a.localeCompare(b));
+  const ids = new Set([...listConfiguredAccountIds(cfg), ...listBoundAccountIds(cfg, "telegram")]);
+  const defaultRes = resolveTelegramToken(cfg, { accountId: DEFAULT_ACCOUNT_ID });
+  if (defaultRes.source !== "none") {
+    ids.add(DEFAULT_ACCOUNT_ID);
+  }
+  const result = Array.from(ids);
+  debugAccounts("listTelegramAccountIds", result);
+  if (result.length === 0) return [DEFAULT_ACCOUNT_ID];
+  return result.sort((a, b) => a.localeCompare(b));
 }
```

**Why?**
Previously, OpenClaw had a "one or many" bug: if you added *any* named bot account (like Felix), it stopped looking for the default account (Amy). I changed the logic to explicitly check if a default token is configured and always include it in the active list. This is why Amy finally came back online!

<!-- slide -->

### 2. Automatic Binding Reloads

**File:** [config-reload.ts](file:///Users/leon/code/forks/openclaw/src/gateway/config-reload.ts)

```diff
   { prefix: "tools", kind: "none" },
-  { prefix: "bindings", kind: "none" },
+  { prefix: "bindings", kind: "restart" },
   { prefix: "audio", kind: "none" },
```

**Why?**
Routing "bindings" are "sticky"—the bots read them when they start up. Before this change, editing the `bindings` section in [openclaw.json](cci:7://file:///Users/leon/.openclaw/openclaw.json:0:0-0:0) would only do a "soft reload" that the bots ignored. By changing this to [restart](cci:1://file:///Users/leon/code/forks/openclaw/src/gateway/server-reload-handlers.ts:118:8-122:10), the Gateway will now automatically recycle the bot providers whenever you change your routing rules, making changes instant.

<!-- slide -->

### 3. Agent Reorganization

**File:** [openclaw.json](file:///Users/leon/.openclaw/openclaw.json)

```json
"agents": {
  "defaults": {
    "workspace": "/Users/leon/admin-workspace"
  },
  "list": [
    { "id": "main" },
    { "id": "amy", "name": "Amy", "workspace": "/Users/leon/main-workspace" }
  ]
}
```

**Why?**
To achieve your **Admin** goal:

- I moved the **default workspace** to a new `admin-workspace`. Since the `main` agent uses the default workspace, it effectively became the Admin.
- I created a **new dedicated `amy` agent** that explicitly points to your original `main-workspace`.
- I then added a **Binding** to ensure your original Telegram bot specifically routes to this new `amy` agent.

<!-- slide -->

### 4. Admin Identity

**File:** [IDENTITY.md](file:///Users/leon/admin-workspace/IDENTITY.md)

```markdown
# IDENTITY.md - OpenClaw Controller
- **Name:** Admin
- **Role:** OpenClaw Controller & System Administrator
- **Vibe:** Professional, efficient, and direct.
```

**Why?**
Since the `main` agent is now your Admin, it needed a new personality! I created this identity file in the new Admin workspace so that if you ever interact with the `main` agent directly, it will act like a system controller rather than your personal assistant.
