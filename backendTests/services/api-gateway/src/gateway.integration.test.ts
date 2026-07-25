import { describe, it, expect, beforeAll, afterAll } from "vitest";
import request from "supertest";
import { resolveIntegrationTarget, type IntegrationTarget } from "../../../test-helpers/integrationTarget";
import { applyForMembership, randomUUID, validApplicationPayload } from "../../../test-helpers/fixtures";

describe("api-gateway Integration", () => {
  let target: IntegrationTarget;
  let baseURL: string;
  const adminKey = process.env.ADMIN_API_KEY ?? "changeme-admin-key";

  beforeAll(async () => {
    target = await resolveIntegrationTarget();
    baseURL = target.gateway;
  }, 30000);

  afterAll(() => target.close());

  describe("Health Check", () => {
    it("should report healthy", async () => {
      const response = await request(baseURL).get("/healthz").expect(200);
      expect(response.body).toMatchObject({ ok: true, service: "api-gateway" });
    });
  });

  describe("Proxying to membership-service under /v1/members", () => {
    it("should route the public application endpoint", async () => {
      const payload = validApplicationPayload();

      const response = await request(baseURL).post("/v1/members/apply").send(payload).expect(201);

      expect(response.body.member).toMatchObject({ firstName: payload.firstName, membershipStatus: "pendingApproval" });
    });

    it("should route the authenticated 'me' endpoint using the member's own token", async () => {
      const { authToken, member } = await applyForMembership(baseURL);

      const response = await request(baseURL)
        .get("/v1/members/me")
        .set("authorization", `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.id).toBe(member.id);
    });
  });

  describe("Proxying to translation-service under /v1/translate", () => {
    it("should route translation requests (public, no auth required)", async () => {
      const response = await request(baseURL)
        .post("/v1/translate")
        .send({ targetLanguage: "es", strings: { hello: "Hola" } })
        .expect(200);

      expect(response.body.strings).toEqual({ hello: "Hola" });
    });
  });

  describe("Chat routes gated behind an active membership", () => {
    it("should reject chat routes without an Authorization header", async () => {
      const response = await request(baseURL).get("/v1/conversations").expect(401);
      expect(response.body.error).toBe("notAuthenticated");
    });

    it("should reject chat routes for a member whose application is still pending", async () => {
      const { authToken } = await applyForMembership(baseURL);

      const response = await request(baseURL)
        .get("/v1/conversations")
        .set("authorization", `Bearer ${authToken}`)
        .expect(403);

      expect(response.body.error).toBe("membershipNotActive");
    });

    it("should route to chat-service once the membership is confirmed, injecting the internal identity headers", async () => {
      const { authToken, member } = await applyForMembership(baseURL);

      await request(baseURL)
        .post(`/v1/admin/members/${member.id}/confirm`)
        .set("x-admin-key", adminKey)
        .expect(200);

      const conversations = await request(baseURL)
        .get("/v1/conversations")
        .set("authorization", `Bearer ${authToken}`)
        .expect(200);

      expect(Array.isArray(conversations.body)).toBe(true);

      const created = await request(baseURL)
        .post("/v1/conversations/individual")
        .set("authorization", `Bearer ${authToken}`)
        .send({ otherUserId: randomUUID() })
        .expect(201);

      expect(created.body.participantIDs).toContain(member.id);
    });
  });

  describe("Service composition through the gateway", () => {
    it("should apply for membership, confirm it, translate a message and send it as a chat message", async () => {
      const { authToken, member } = await applyForMembership(baseURL);
      await request(baseURL).post(`/v1/admin/members/${member.id}/confirm`).set("x-admin-key", adminKey).expect(200);

      const translation = await request(baseURL)
        .post("/v1/translate")
        .send({ targetLanguage: "es", strings: { welcome: "Benvingut a l'associació" } })
        .expect(200);

      const conversation = await request(baseURL)
        .post("/v1/conversations/individual")
        .set("authorization", `Bearer ${authToken}`)
        .send({ otherUserId: randomUUID() })
        .expect(201);

      const message = await request(baseURL)
        .post(`/v1/conversations/${conversation.body.id}/messages`)
        .set("authorization", `Bearer ${authToken}`)
        .send({ text: translation.body.strings.welcome })
        .expect(201);

      expect(message.body).toMatchObject({ senderID: member.id, text: translation.body.strings.welcome });
    });
  });

  describe("Error handling", () => {
    it("should return 404 for a route with no matching proxy", async () => {
      await request(baseURL).get("/this-route-does-not-exist").expect(404);
    });
  });

  describe("CORS", () => {
    it("should include CORS headers on responses", async () => {
      const response = await request(baseURL).get("/healthz").set("Origin", "http://localhost:3000").expect(200);
      expect(response.headers["access-control-allow-origin"]).toBeDefined();
    });
  });
});
