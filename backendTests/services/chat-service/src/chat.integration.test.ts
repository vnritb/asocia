import { describe, it, expect, beforeAll, afterAll } from "vitest";
import request from "supertest";
import { resolveIntegrationTarget, type IntegrationTarget } from "../../../test-helpers/integrationTarget";
import { randomUUID } from "../../../test-helpers/fixtures";

function userHeaders(userId: string, userName: string) {
  return { "x-user-id": userId, "x-user-name": encodeURIComponent(userName) };
}

describe("chat-service Integration", () => {
  let target: IntegrationTarget;
  let baseURL: string;
  const internalKey = process.env.INTERNAL_API_KEY ?? "changeme-internal-key";

  beforeAll(async () => {
    target = await resolveIntegrationTarget();
    baseURL = target.chat;
  }, 30000);

  afterAll(() => target.close());

  describe("Health Check", () => {
    it("should report healthy", async () => {
      const response = await request(baseURL).get("/healthz").expect(200);
      expect(response.body).toMatchObject({ ok: true, service: "chat-service" });
    });
  });

  describe("Authentication", () => {
    it("should reject requests without identity headers", async () => {
      const response = await request(baseURL).get("/v1/conversations").expect(401);
      expect(response.body.error).toBe("notAuthenticated");
    });
  });

  describe("Directory (internal sync + search)", () => {
    it("should reject internal directory writes without the internal key", async () => {
      await request(baseURL)
        .post("/internal/directory/upsert")
        .send({ userId: randomUUID(), fullName: "Sin Clave" })
        .expect(403);
    });

    it("should list a member added via the internal upsert endpoint", async () => {
      const userId = randomUUID();
      const me = randomUUID();
      await request(baseURL)
        .post("/internal/directory/upsert")
        .set("x-internal-key", internalKey)
        .send({ userId, fullName: "Pedro Jiménez" })
        .expect(204);

      const response = await request(baseURL).get("/v1/directory").set(userHeaders(me, "Yo")).expect(200);

      expect(response.body.some((u: { id: string }) => u.id === userId)).toBe(true);
    });

    it("should find a fuzzy match by query", async () => {
      const userId = randomUUID();
      const me = randomUUID();
      await request(baseURL)
        .post("/internal/directory/upsert")
        .set("x-internal-key", internalKey)
        .send({ userId, fullName: "Antonio Giménez" })
        .expect(204);

      const response = await request(baseURL)
        .get("/v1/directory")
        .query({ query: "Antonio Gimenez" })
        .set(userHeaders(me, "Yo"))
        .expect(200);

      expect(response.body.some((u: { id: string }) => u.id === userId)).toBe(true);
    });

    it("should remove a member via the internal remove endpoint", async () => {
      const userId = randomUUID();
      const me = randomUUID();
      await request(baseURL)
        .post("/internal/directory/upsert")
        .set("x-internal-key", internalKey)
        .send({ userId, fullName: "Socio Temporal" })
        .expect(204);
      await request(baseURL)
        .post("/internal/directory/remove")
        .set("x-internal-key", internalKey)
        .send({ userId })
        .expect(204);

      const response = await request(baseURL).get("/v1/directory").set(userHeaders(me, "Yo")).expect(200);

      expect(response.body.some((u: { id: string }) => u.id === userId)).toBe(false);
    });
  });

  describe("Individual conversations & messages", () => {
    it("should open an individual conversation and exchange messages", async () => {
      const alice = randomUUID();
      const bob = randomUUID();

      const created = await request(baseURL)
        .post("/v1/conversations/individual")
        .set(userHeaders(alice, "Alice"))
        .send({ otherUserId: bob })
        .expect(201);

      expect(created.body.kind).toBe("individual");
      expect(created.body.participantIDs.sort()).toEqual([alice, bob].sort());

      const conversationId = created.body.id;

      const message = await request(baseURL)
        .post(`/v1/conversations/${conversationId}/messages`)
        .set(userHeaders(alice, "Alice"))
        .send({ text: "Hola Bob!" })
        .expect(201);

      expect(message.body).toMatchObject({ senderID: alice, text: "Hola Bob!" });

      const messages = await request(baseURL)
        .get(`/v1/conversations/${conversationId}/messages`)
        .set(userHeaders(bob, "Bob"))
        .expect(200);

      expect(messages.body).toHaveLength(1);

      const conversations = await request(baseURL)
        .get("/v1/conversations")
        .set(userHeaders(bob, "Bob"))
        .expect(200);

      expect(conversations.body.some((c: { id: string }) => c.id === conversationId)).toBe(true);
    });

    it("should return the same conversation when opened a second time between the same pair", async () => {
      const alice = randomUUID();
      const bob = randomUUID();

      const first = await request(baseURL)
        .post("/v1/conversations/individual")
        .set(userHeaders(alice, "Alice"))
        .send({ otherUserId: bob })
        .expect(201);

      const second = await request(baseURL)
        .post("/v1/conversations/individual")
        .set(userHeaders(bob, "Bob"))
        .send({ otherUserId: alice })
        .expect(200);

      expect(second.body.id).toBe(first.body.id);
    });

    it("should reject reading messages from a conversation you don't belong to", async () => {
      const alice = randomUUID();
      const bob = randomUUID();
      const intruder = randomUUID();

      const created = await request(baseURL)
        .post("/v1/conversations/individual")
        .set(userHeaders(alice, "Alice"))
        .send({ otherUserId: bob })
        .expect(201);

      await request(baseURL)
        .get(`/v1/conversations/${created.body.id}/messages`)
        .set(userHeaders(intruder, "Intruso"))
        .expect(403);
    });

    it("should reject an empty message", async () => {
      const alice = randomUUID();
      const bob = randomUUID();
      const created = await request(baseURL)
        .post("/v1/conversations/individual")
        .set(userHeaders(alice, "Alice"))
        .send({ otherUserId: bob })
        .expect(201);

      const response = await request(baseURL)
        .post(`/v1/conversations/${created.body.id}/messages`)
        .set(userHeaders(alice, "Alice"))
        .send({ text: "   " })
        .expect(422);

      expect(response.body.error).toBe("emptyMessage");
    });
  });

  describe("Group conversations", () => {
    it("should create a group conversation with all participants", async () => {
      const creator = randomUUID();
      const memberA = randomUUID();
      const memberB = randomUUID();

      const response = await request(baseURL)
        .post("/v1/conversations/group")
        .set(userHeaders(creator, "Creador"))
        .send({ title: "Junta directiva", participantIds: [memberA, memberB] })
        .expect(201);

      expect(response.body.kind).toBe("group");
      expect(response.body.title).toBe("Junta directiva");
      expect(response.body.participantIDs.sort()).toEqual([creator, memberA, memberB].sort());
    });

    it("should reject a group without a title", async () => {
      const response = await request(baseURL)
        .post("/v1/conversations/group")
        .set(userHeaders(randomUUID(), "Creador"))
        .send({ title: "", participantIds: [randomUUID()] })
        .expect(422);

      expect(response.body.error).toBe("emptyTitle");
    });
  });

  describe("Activities & events", () => {
    it("should list an activity room in /v1/conversations/activities and allow requesting access", async () => {
      const creator = randomUUID();
      const outsider = randomUUID();

      const activity = await request(baseURL)
        .post("/v1/conversations/activity")
        .set(userHeaders(creator, "Creador"))
        .send({ title: "Sortida de muntanya", participantIds: [] })
        .expect(201);

      const listed = await request(baseURL)
        .get("/v1/conversations/activities")
        .set(userHeaders(outsider, "Outsider"))
        .expect(200);

      const summary = listed.body.find((s: { conversation: { id: string } }) => s.conversation.id === activity.body.id);
      expect(summary).toBeDefined();
      expect(summary.isParticipant).toBe(false);

      const requestAccess = await request(baseURL)
        .post(`/v1/conversations/${activity.body.id}/request-access`)
        .set(userHeaders(outsider, "Outsider"))
        .expect(201);

      expect(requestAccess.body.status).toBe("pending");
    });

    it("should create an event via the admin route and let a participant confirm attendance", async () => {
      const creator = randomUUID();
      const attendee = randomUUID();

      const activity = await request(baseURL)
        .post("/v1/conversations/activity")
        .set(userHeaders(creator, "Creador"))
        .send({ title: "Sopar anual", participantIds: [attendee] })
        .expect(201);

      const event = await request(baseURL)
        .post("/v1/admin/events")
        .set("x-internal-key", internalKey)
        .send({
          conversationId: activity.body.id,
          title: "Sopar anual 2026",
          startDate: new Date(Date.now() + 86400000).toISOString(),
          attendees: [{ id: attendee, name: "Assistent" }]
        })
        .expect(201);

      expect(event.body.attendees).toEqual([{ id: attendee, name: "Assistent", status: "invited" }]);

      const confirmed = await request(baseURL)
        .post(`/v1/events/${event.body.id}/confirm`)
        .set(userHeaders(attendee, "Assistent"))
        .expect(200);

      expect(confirmed.body.attendees.find((a: { id: string }) => a.id === attendee)?.status).toBe("confirmed");
    });

    it("should return 404 confirming a non-existent event", async () => {
      await request(baseURL)
        .post(`/v1/events/${randomUUID()}/confirm`)
        .set(userHeaders(randomUUID(), "Nadie"))
        .expect(404);
    });
  });
});
