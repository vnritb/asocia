import express from "express";
import cors from "cors";
import type { TranslateRequest, TranslateResponse } from "@asocia/shared";
import { pool, ensureSchema } from "./db";
import { translateWithClaude } from "./anthropic";

const PORT = Number(process.env.PORT ?? 4003);
const BASE_LANGUAGE = "es";

const app = express();
app.use(cors());
app.use(express.json({ limit: "2mb" }));

app.get("/healthz", (_req, res) => res.json({ ok: true, service: "translation-service" }));

/**
 * Traduce (con caché) el diccionario de textos de la app al idioma pedido.
 *
 * 1. El español (idioma base) se devuelve tal cual, sin llamar a la IA.
 * 2. Para el resto de idiomas, se buscan en `translation.translations` las
 *    claves que ya se hayan traducido antes (para CUALQUIER usuario, no
 *    solo para quien pide ahora) y solo se manda a Claude lo que falte.
 * 3. Lo nuevo se guarda en caché para la próxima persona que elija ese idioma.
 */
app.post("/v1/translate", async (req, res) => {
  const body = req.body as TranslateRequest;
  if (!body?.targetLanguage || !body?.strings) {
    return res.status(422).json({ error: "invalidPayload" });
  }

  if (body.targetLanguage === BASE_LANGUAGE) {
    const response: TranslateResponse = { strings: body.strings };
    return res.json(response);
  }

  const keys = Object.keys(body.strings);
  if (keys.length === 0) {
    return res.json({ strings: {} } satisfies TranslateResponse);
  }

  const cached = await pool.query(
    "SELECT key, value FROM translation.translations WHERE language_code = $1 AND key = ANY($2)",
    [body.targetLanguage, keys]
  );
  const cachedMap: Record<string, string> = Object.fromEntries(cached.rows.map((r) => [r.key, r.value]));

  const missingKeys = keys.filter((key) => !(key in cachedMap));
  let translatedMissing: Record<string, string> = {};

  if (missingKeys.length > 0) {
    const missingStrings = Object.fromEntries(missingKeys.map((key) => [key, body.strings[key]]));
    try {
      translatedMissing = await translateWithClaude(missingStrings, body.targetLanguage);
    } catch (error) {
      console.error("Fallo traduciendo con Claude:", error);
      // Si la IA falla, devolvemos al menos el español para esas claves en
      // vez de romper toda la pantalla de Ajustes.
      translatedMissing = missingStrings;
    }

    const client = await pool.connect();
    try {
      await client.query("BEGIN");
      for (const [key, value] of Object.entries(translatedMissing)) {
        await client.query(
          `INSERT INTO translation.translations (language_code, key, value)
           VALUES ($1, $2, $3)
           ON CONFLICT (language_code, key) DO UPDATE SET value = EXCLUDED.value, updated_at = now()`,
          [body.targetLanguage, key, value]
        );
      }
      await client.query("COMMIT");
    } catch (error) {
      await client.query("ROLLBACK");
      throw error;
    } finally {
      client.release();
    }
  }

  const response: TranslateResponse = { strings: { ...cachedMap, ...translatedMissing } };
  res.json(response);
});

ensureSchema()
  .then(() => {
    app.listen(PORT, () => console.log(`translation-service escuchando en :${PORT}`));
  })
  .catch((error) => {
    console.error("No se pudo preparar el esquema de translation-service:", error);
    process.exit(1);
  });
