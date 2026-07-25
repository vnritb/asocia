import { describe, it, expect, beforeAll, afterAll } from "vitest";
import request from "supertest";
import { resolveIntegrationTarget, type IntegrationTarget } from "../../../test-helpers/integrationTarget";

describe("translation-service Integration", () => {
  let target: IntegrationTarget;
  let baseURL: string;

  beforeAll(async () => {
    target = await resolveIntegrationTarget();
    baseURL = target.translation;
  }, 30000);

  afterAll(() => target.close());

  describe("Health Check", () => {
    it("should report healthy", async () => {
      const response = await request(baseURL).get("/healthz").expect(200);
      expect(response.body).toMatchObject({ ok: true, service: "translation-service" });
    });
  });

  describe("POST /v1/translate", () => {
    it("should return the base language (es) untouched, without calling the translator", async () => {
      const response = await request(baseURL)
        .post("/v1/translate")
        .send({ targetLanguage: "es", strings: { greeting: "Hola" } })
        .expect(200);

      expect(response.body.strings).toEqual({ greeting: "Hola" });
    });

    it("should translate missing keys into the target language", async () => {
      const key = `greeting-${Date.now()}`;

      const response = await request(baseURL)
        .post("/v1/translate")
        .send({ targetLanguage: "fr", strings: { [key]: "Hola" } })
        .expect(200);

      expect(response.body.strings[key]).toEqual(expect.any(String));
      expect(response.body.strings[key]).not.toBe("Hola");
    });

    it("should serve already-translated keys from cache on a second request", async () => {
      const key = `cached-${Date.now()}`;

      const first = await request(baseURL)
        .post("/v1/translate")
        .send({ targetLanguage: "de", strings: { [key]: "Adiós" } })
        .expect(200);

      const second = await request(baseURL)
        .post("/v1/translate")
        .send({ targetLanguage: "de", strings: { [key]: "Adiós" } })
        .expect(200);

      expect(second.body.strings[key]).toBe(first.body.strings[key]);
    });

    it("should return an empty dictionary when strings is empty", async () => {
      const response = await request(baseURL)
        .post("/v1/translate")
        .send({ targetLanguage: "fr", strings: {} })
        .expect(200);

      expect(response.body.strings).toEqual({});
    });

    it("should return 422 when targetLanguage is missing", async () => {
      const response = await request(baseURL)
        .post("/v1/translate")
        .send({ strings: { greeting: "Hola" } })
        .expect(422);

      expect(response.body.error).toBe("invalidPayload");
    });

    it("should return 422 when strings is missing", async () => {
      const response = await request(baseURL)
        .post("/v1/translate")
        .send({ targetLanguage: "fr" })
        .expect(422);

      expect(response.body.error).toBe("invalidPayload");
    });
  });
});
