import { describe, it, expect, beforeAll, afterAll } from "vitest";
import request from "supertest";
import { resolveIntegrationTarget, type IntegrationTarget } from "../../../test-helpers/integrationTarget";
import {
  applyForMembership,
  createActiveMember,
  randomUUID,
  validApplicationPayload
} from "../../../test-helpers/fixtures";

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
      const { authToken, member } = await createActiveMember(baseURL);

      const response = await request(baseURL)
        .get("/v1/members/me")
        .set("authorization", `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.id).toBe(member.id);
    });
  });

  describe("Chat routes gated behind an active membership", () => {
    it("should reject chat routes without an Authorization header", async () => {
      const response = await request(baseURL).get("/v1/conversations").expect(401);
      expect(response.body.error).toBe("notAuthenticated");
    });

    it("should not hand out a session token (and so block chat access) while the application is still pending", async () => {
      // Ya no hay forma de que un cliente obtenga un token para un socio
      // pendiente: ni /apply ni /login lo devuelven hasta que está active
      // (ver membership.integration.test.ts). Comprobamos justamente eso a
      // través del gateway, que es donde vive el guardián de chat.
      const { email, passwordHash } = await applyForMembership(baseURL);

      const status = await request(baseURL).post("/v1/members/login").send({ email, passwordHash }).expect(403);
      expect(status.body.error).toBe("pendingApproval");
    });

    it("should route to chat-service once the membership is confirmed, injecting the internal identity headers", async () => {
      const { authToken, member } = await createActiveMember(baseURL);

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
    it("should apply for membership, confirm it, log in and send a chat message", async () => {
      const { authToken, member } = await createActiveMember(baseURL);

      const conversation = await request(baseURL)
        .post("/v1/conversations/individual")
        .set("authorization", `Bearer ${authToken}`)
        .send({ otherUserId: randomUUID() })
        .expect(201);

      const message = await request(baseURL)
        .post(`/v1/conversations/${conversation.body.id}/messages`)
        .set("authorization", `Bearer ${authToken}`)
        .send({ text: "Benvingut a l'associació" })
        .expect(201);

      expect(message.body).toMatchObject({ senderID: member.id, text: "Benvingut a l'associació" });
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
