import { vi } from "vitest";

// Sustituye el driver real de Postgres por el almacén en memoria de fakePg.ts
// para todos los servicios (cada uno crea su propio `new Pool()` en su
// `db.ts`, así que cada instancia tiene sus propios datos).
vi.mock("pg", () => import("./fakePg"));

// Evita llamar a la API real de Anthropic durante los tests de integración
// mockeados: traduce devolviendo el texto original prefijado con el idioma,
// suficiente para comprobar el contrato del endpoint sin gastar tokens.
vi.mock("../../backend/services/translation-service/src/anthropic", () => ({
  translateWithClaude: vi.fn(async (strings: Record<string, string>, targetLanguageCode: string) => {
    return Object.fromEntries(Object.entries(strings).map(([key, value]) => [key, `[${targetLanguageCode}] ${value}`]));
  })
}));
