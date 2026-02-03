import path from "node:path";
import { describe, expect, it, vi, afterEach } from "vitest";
import { resolveImplicitProviders } from "./models-config.providers.js";

describe("resolveImplicitProviders - OpenRouter", () => {
  const agentDir = path.resolve("/tmp/test-agent");

  afterEach(() => {
    vi.unstubAllEnvs();
  });

  it("discovers openrouter provider when OPENROUTER_API_KEY is set", async () => {
    vi.stubEnv("OPENROUTER_API_KEY", "sk-test-key");

    // We need to mock ensureAuthProfileStore to return something empty or mock it out entirely
    // But since we are relying on Env var, it should work if we just stub the env.
    // However, resolveImplicitProviders calls ensureAuthProfileStore which might try to access disk.
    // Let's rely on the fact that ensureAuthProfileStore likely handles non-existent dirs gracefully or we might need to mock it.

    // Actually, looking at the code:
    // const authStore = ensureAuthProfileStore(params.agentDir, { allowKeychainPrompt: false });
    // This will probably create a directory. Let's use written file mocks if needed,
    // but first let's try to see if we can run it without deep mocks if the function is robust.

    const providers = await resolveImplicitProviders({ agentDir });
    if (!providers) {
      throw new Error("providers is undefined");
    }
    expect(providers.openrouter).toBeDefined();
    expect(providers.openrouter.baseUrl).toBe("https://openrouter.ai/api/v1");
    expect(providers.openrouter.apiKey).toBe("OPENROUTER_API_KEY");
    expect(providers.openrouter.api).toBe("openai-completions");
  });
});
