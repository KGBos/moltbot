import fs from "fs/promises";
import path from "path";
import { STATE_DIR } from "../config/paths.js";
import type { ResolvedTtsConfig, TtsRequest, TtsResult } from "./tts.js";

async function ensureMediaDir(): Promise<string> {
  const dir = path.join(STATE_DIR, "media");
  await fs.mkdir(dir, { recursive: true });
  return dir;
}

interface ChatterboxTtsResponse {
  error?: string;
}

export async function chatterboxTts(
  req: TtsRequest,
  config: ResolvedTtsConfig,
): Promise<TtsResult> {
  const serverUrl = config.chatterbox?.url ?? "http://localhost:5050";
  const endpoint = `${serverUrl}/tts`;

  try {
    const response = await fetch(endpoint, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        text: req.text,
        voice_prompt: config.chatterbox?.defaultVoicePath,
      }),
    });
    console.log(`[Chatterbox] Response status: ${response.status}`);

    if (!response.ok) {
      if (response.headers.get("content-type")?.includes("application/json")) {
        const json = (await response.json()) as ChatterboxTtsResponse;
        return {
          success: false,
          error: `Chatterbox server error: ${json.error || response.statusText}`,
          provider: "chatterbox",
        };
      }
      return {
        success: false,
        error: `Chatterbox server error: ${response.status} ${response.statusText}`,
        provider: "chatterbox",
      };
    }

    const arrayBuffer = await response.arrayBuffer();
    const buffer = Buffer.from(arrayBuffer);

    // Ensure output directory exists
    const mediaDir = await ensureMediaDir();
    const filename = `chatterbox-${Date.now()}-${Math.random().toString(36).substring(7)}.wav`;
    const filePath = path.join(mediaDir, filename);

    await fs.writeFile(filePath, buffer);

    return {
      success: true,
      audioPath: filePath,
      provider: "chatterbox",
      voiceCompatible: false,
    };
  } catch (error) {
    console.error("Chatterbox Error:", error);
    return {
      success: false,
      error: `Failed to connect to Chatterbox server at ${serverUrl}: ${error}`,
      provider: "chatterbox",
    };
  }
}
