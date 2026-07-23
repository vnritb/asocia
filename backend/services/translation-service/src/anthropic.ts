const ANTHROPIC_API_URL = "https://api.anthropic.com/v1/messages";
const ANTHROPIC_VERSION = "2023-06-01";
const CHUNK_SIZE = 60; // nº de claves por llamada, para no mandar prompts gigantes

/**
 * Traduce un lote de textos (clave -> español) a `targetLanguageCode`
 * (código ISO 639-1, p.ej. "fr", "eu", "zh") usando la API de Anthropic.
 * Divide el diccionario en trozos de `CHUNK_SIZE` claves para mantener los
 * prompts manejables y evitar respuestas truncadas.
 */
export async function translateWithClaude(
  strings: Record<string, string>,
  targetLanguageCode: string
): Promise<Record<string, string>> {
  const apiKey = process.env.ANTHROPIC_API_KEY;
  if (!apiKey) {
    throw new Error("ANTHROPIC_API_KEY no configurada en translation-service");
  }

  const entries = Object.entries(strings);
  const result: Record<string, string> = {};

  for (let i = 0; i < entries.length; i += CHUNK_SIZE) {
    const chunk = Object.fromEntries(entries.slice(i, i + CHUNK_SIZE));
    const translatedChunk = await translateChunk(chunk, targetLanguageCode, apiKey);
    Object.assign(result, translatedChunk);
  }

  return result;
}

async function translateChunk(
  chunk: Record<string, string>,
  targetLanguageCode: string,
  apiKey: string
): Promise<Record<string, string>> {
  const model = process.env.ANTHROPIC_MODEL ?? "claude-haiku-4-5-20251001";

  const systemPrompt = [
    "Eres un traductor profesional de interfaces de aplicaciones móviles.",
    "Traduces del español al idioma solicitado, con un tono neutro, breve y natural,",
    "igual que los textos de cualquier app nativa en ese idioma.",
    "Conserva tal cual cualquier marcador de formato como %d o %@.",
    "No añadas explicaciones ni comentarios.",
    "Responde EXCLUSIVAMENTE con un objeto JSON válido, con las mismas claves",
    "que la entrada, cuyo valor sea el texto traducido. Nada de texto antes ni después del JSON."
  ].join(" ");

  const userPrompt =
    `Traduce estos textos al idioma con código ISO 639-1 "${targetLanguageCode}". ` +
    `Textos de entrada (JSON clave -> español):\n${JSON.stringify(chunk, null, 2)}`;

  const response = await fetch(ANTHROPIC_API_URL, {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "x-api-key": apiKey,
      "anthropic-version": ANTHROPIC_VERSION
    },
    body: JSON.stringify({
      model,
      max_tokens: 4096,
      system: systemPrompt,
      messages: [{ role: "user", content: userPrompt }]
    })
  });

  if (!response.ok) {
    const body = await response.text().catch(() => "");
    throw new Error(`Anthropic API respondió ${response.status}: ${body}`);
  }

  const payload = (await response.json()) as { content: { type: string; text?: string }[] };
  const text = payload.content.find((block) => block.type === "text")?.text ?? "";

  return parseJsonObject(text, chunk);
}

/** Quita posibles fences ```json ... ``` y parsea; si algo falla, devuelve el propio chunk sin traducir para no perder claves. */
function parseJsonObject(rawText: string, fallback: Record<string, string>): Record<string, string> {
  const cleaned = rawText.trim().replace(/^```(json)?/i, "").replace(/```$/, "").trim();
  try {
    const parsed = JSON.parse(cleaned);
    if (parsed && typeof parsed === "object") return parsed as Record<string, string>;
  } catch {
    // seguimos al fallback
  }
  return fallback;
}
