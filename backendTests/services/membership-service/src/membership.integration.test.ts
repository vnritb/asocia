import { describe, it, expect, beforeAll, afterAll } from "vitest";
import request from "supertest";
import { resolveIntegrationTarget, type IntegrationTarget } from "../../../test-helpers/integrationTarget";
import { applyForMembership, createActiveMember, validApplicationPayload } from "../../../test-helpers/fixtures";

describe("membership-service Integration", () => {
  let target: IntegrationTarget;
  let baseURL: string;

  beforeAll(async () => {
    target = await resolveIntegrationTarget();
    baseURL = target.membership;
  }, 30000);

  afterAll(() => target.close());

  describe("Health Check", () => {
    it("should report healthy", async () => {
      const response = await request(baseURL).get("/healthz").expect(200);
      expect(response.body).toMatchObject({ ok: true, service: "membership-service" });
    });
  });

  describe("POST /v1/members/apply", () => {
    it("should create a pending application and NOT return an authToken", async () => {
      const payload = validApplicationPayload();

      const response = await request(baseURL).post("/v1/members/apply").send(payload).expect(201);

      expect(response.body.authToken).toBeUndefined();
      expect(response.body.member).toMatchObject({
        id: expect.any(String),
        firstName: payload.firstName,
        firstSurname: payload.firstSurname,
        email: payload.email,
        membershipStatus: "pendingApproval"
      });
    });

    it("should reject an application without firstName/firstSurname", async () => {
      const response = await request(baseURL)
        .post("/v1/members/apply")
        .send({ email: "sin-nombre@example.com", mobilePhone: "+34600000000" })
        .expect(422);

      expect(response.body.error).toBe("invalidApplication");
    });

    it("should reject an application without any contact method", async () => {
      const response = await request(baseURL)
        .post("/v1/members/apply")
        .send({ firstName: "Sin", firstSurname: "Contacto" })
        .expect(422);

      expect(response.body.error).toBe("invalidApplication");
    });

    it("should reject a second application with the same email", async () => {
      const payload = validApplicationPayload();
      await request(baseURL).post("/v1/members/apply").send(payload).expect(201);

      const response = await request(baseURL)
        .post("/v1/members/apply")
        .send({ ...payload, firstName: "Otro" })
        .expect(409);

      expect(response.body.error).toBe("emailAlreadyExists");
    });
  });

  describe("GET /v1/members/:id/status", () => {
    it("should report pendingApproval without a token while unconfirmed", async () => {
      const { member } = await applyForMembership(baseURL);

      const response = await request(baseURL).get(`/v1/members/${member.id}/status`).expect(200);

      expect(response.body).toMatchObject({ membershipStatus: "pendingApproval" });
      expect(response.body.authToken).toBeUndefined();
    });

    it("should return an authToken once the application is confirmed", async () => {
      const { member, email } = await applyForMembership(baseURL);
      const adminKey = process.env.ADMIN_API_KEY ?? "changeme-admin-key";
      await request(baseURL).post(`/v1/admin/members/${member.id}/confirm`).set("x-admin-key", adminKey).expect(200);

      const response = await request(baseURL).get(`/v1/members/${member.id}/status`).expect(200);

      expect(response.body.membershipStatus).toBe("active");
      expect(response.body.authToken).toEqual(expect.any(String));
      expect(response.body.member).toMatchObject({ id: member.id, email });
    });

    it("should return 404 for an unknown id", async () => {
      await request(baseURL).get("/v1/members/00000000-0000-0000-0000-000000000000/status").expect(404);
    });
  });

  describe("POST /v1/members/login", () => {
    it("should reject unknown credentials", async () => {
      const response = await request(baseURL)
        .post("/v1/members/login")
        .send({ email: "no-existe@example.com", passwordHash: "whatever" })
        .expect(401);

      expect(response.body.error).toBe("invalidCredentials");
    });

    it("should reject a correct email with the wrong password hash", async () => {
      const { email } = await applyForMembership(baseURL);

      const response = await request(baseURL)
        .post("/v1/members/login")
        .send({ email, passwordHash: "not-the-right-hash" })
        .expect(401);

      expect(response.body.error).toBe("invalidCredentials");
    });

    it("should reject valid credentials while the application is still pending", async () => {
      const { email, passwordHash } = await applyForMembership(baseURL);

      const response = await request(baseURL).post("/v1/members/login").send({ email, passwordHash }).expect(403);

      expect(response.body.error).toBe("pendingApproval");
    });

    it("should return an authToken for valid credentials once active", async () => {
      const { authToken, member } = await createActiveMember(baseURL);
      expect(authToken).toEqual(expect.any(String));

      const response = await request(baseURL)
        .get("/v1/members/me")
        .set("authorization", `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.id).toBe(member.id);
    });
  });

  describe("GET /v1/members/me", () => {
    it("should return the member's own record for a valid token", async () => {
      const { authToken, member } = await createActiveMember(baseURL);

      const response = await request(baseURL)
        .get("/v1/members/me")
        .set("authorization", `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.id).toBe(member.id);
    });

    it("should return 401 without a token", async () => {
      await request(baseURL).get("/v1/members/me").expect(401);
    });

    it("should return 401 for an invalid token", async () => {
      const response = await request(baseURL)
        .get("/v1/members/me")
        .set("authorization", "Bearer not-a-real-token")
        .expect(401);

      expect(response.body.error).toBe("notAuthenticated");
    });
  });

  describe("PATCH /v1/members/me", () => {
    it("should update editable fields", async () => {
      const { authToken } = await createActiveMember(baseURL);

      const response = await request(baseURL)
        .patch("/v1/members/me")
        .set("authorization", `Bearer ${authToken}`)
        .send({ city: "Barcelona", profession: "Enginyera" })
        .expect(200);

      expect(response.body).toMatchObject({ city: "Barcelona", profession: "Enginyera" });
    });

    it("should not allow the member to change their own membershipStatus", async () => {
      const { authToken, member } = await createActiveMember(baseURL);

      const response = await request(baseURL)
        .patch("/v1/members/me")
        .set("authorization", `Bearer ${authToken}`)
        .send({ membershipStatus: "rejected" })
        .expect(200);

      expect(response.body.membershipStatus).toBe(member.membershipStatus);
    });
  });

  describe("Admin routes", () => {
    it("should reject admin routes without x-admin-key", async () => {
      const response = await request(baseURL).get("/v1/admin/members").expect(403);
      expect(response.body.error).toBe("forbidden");
    });

    it("should list members for the backoffice", async () => {
      await applyForMembership(baseURL);
      const adminKey = process.env.ADMIN_API_KEY ?? "changeme-admin-key";

      const response = await request(baseURL).get("/v1/admin/members").set("x-admin-key", adminKey).expect(200);

      expect(Array.isArray(response.body)).toBe(true);
      expect(response.body.length).toBeGreaterThan(0);
    });

    it("should filter members by status", async () => {
      const adminKey = process.env.ADMIN_API_KEY ?? "changeme-admin-key";
      const { member } = await createActiveMember(baseURL);

      const response = await request(baseURL)
        .get("/v1/admin/members")
        .query({ status: "active" })
        .set("x-admin-key", adminKey)
        .expect(200);

      expect(response.body.some((m: { id: string }) => m.id === member.id)).toBe(true);
      expect(response.body.every((m: { membershipStatus: string }) => m.membershipStatus === "active")).toBe(true);
    });

    it("should confirm a pending application", async () => {
      const adminKey = process.env.ADMIN_API_KEY ?? "changeme-admin-key";
      const { member } = await applyForMembership(baseURL);

      const response = await request(baseURL)
        .post(`/v1/admin/members/${member.id}/confirm`)
        .set("x-admin-key", adminKey)
        .expect(200);

      expect(response.body.membershipStatus).toBe("active");
      expect(response.body.joinDate).toEqual(expect.any(String));
    });

    it("should reject a pending application with a reason", async () => {
      const adminKey = process.env.ADMIN_API_KEY ?? "changeme-admin-key";
      const { member } = await applyForMembership(baseURL);

      const response = await request(baseURL)
        .post(`/v1/admin/members/${member.id}/reject`)
        .set("x-admin-key", adminKey)
        .send({ reason: "Datos incompletos" })
        .expect(200);

      expect(response.body).toMatchObject({ membershipStatus: "rejected", rejectionReason: "Datos incompletos" });
    });

    it("should return 404 when confirming a non-existent member", async () => {
      const adminKey = process.env.ADMIN_API_KEY ?? "changeme-admin-key";

      const response = await request(baseURL)
        .post("/v1/admin/members/00000000-0000-0000-0000-000000000000/confirm")
        .set("x-admin-key", adminKey)
        .expect(404);

      expect(response.body.error).toBe("notFound");
    });
  });
});
