import crypto from "node:crypto";
import request from "supertest";
import type { Member } from "@asocia/shared";

let counter = 0;

/** Datos de alta válidos para POST /v1/members/apply (nombre + apellido + contacto). */
export function validApplicationPayload(overrides: Partial<Member> = {}) {
  counter += 1;
  return {
    firstName: "Ana",
    firstSurname: "García",
    secondSurname: "López",
    email: `ana-${Date.now()}-${counter}@example.com`,
    mobilePhone: "+34600000000",
    isSearchable: true,
    ...overrides
  };
}

/** Da de alta un socio contra membership-service y devuelve su authToken + ficha. */
export async function applyForMembership(
  membershipURL: string,
  overrides: Partial<Member> = {}
): Promise<{ authToken: string; member: Member }> {
  const response = await request(membershipURL)
    .post("/v1/members/apply")
    .send(validApplicationPayload(overrides))
    .expect(201);
  return response.body;
}

/** Da de alta y confirma un socio (membership_status: active), como haría el backoffice. */
export async function createActiveMember(
  membershipURL: string,
  overrides: Partial<Member> = {}
): Promise<{ authToken: string; member: Member }> {
  const { authToken, member } = await applyForMembership(membershipURL, overrides);
  const adminKey = process.env.ADMIN_API_KEY ?? "changeme-admin-key";
  const confirmed = await request(membershipURL)
    .post(`/v1/admin/members/${member.id}/confirm`)
    .set("x-admin-key", adminKey)
    .expect(200);
  return { authToken, member: confirmed.body };
}

export function randomUUID(): string {
  return crypto.randomUUID();
}
