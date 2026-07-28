import crypto from "node:crypto";
import request from "supertest";
import type { Member } from "@asocia/shared";

/** Datos de alta válidos para POST /v1/members/apply (nombre + apellido + contacto). */
export function validApplicationPayload(overrides: Partial<Member> & { passwordHash?: string } = {}) {
  return {
    firstName: "Ana",
    firstSurname: "García",
    secondSurname: "López",
    // crypto.randomUUID() en vez de Date.now()+contador: varios ficheros de
    // test corren en paralelo, cada uno con su propia instancia de este
    // módulo (y por tanto su propio contador reiniciado a 0), así que
    // Date.now()+contador podía coincidir entre ficheros — y ahora que
    // /apply rechaza emails duplicados (409 emailAlreadyExists), esa
    // coincidencia rompía tests en vez de pasar desapercibida.
    email: `ana-${crypto.randomUUID()}@example.com`,
    mobilePhone: "+34600000000",
    isSearchable: true,
    passwordHash: "test-password-hash",
    ...overrides
  };
}

/**
 * Da de alta un socio contra membership-service. A propósito NO devuelve
 * authToken (ver MembershipApplicationResponse): mientras el alta esté
 * pendingApproval no hay sesión. Para un socio con sesión usable, ver
 * `createActiveMember`.
 */
export async function applyForMembership(
  membershipURL: string,
  overrides: Partial<Member> & { passwordHash?: string } = {}
): Promise<{ member: Member; email: string; passwordHash: string }> {
  const payload = validApplicationPayload(overrides);
  const response = await request(membershipURL).post("/v1/members/apply").send(payload).expect(201);
  return { member: response.body.member, email: payload.email, passwordHash: payload.passwordHash };
}

/** POST /v1/members/login. Solo tiene éxito si el socio está `active`. */
export async function loginAsMember(
  membershipURL: string,
  email: string,
  passwordHash: string
): Promise<{ authToken: string; member: Member }> {
  const response = await request(membershipURL)
    .post("/v1/members/login")
    .send({ email, passwordHash })
    .expect(200);
  return response.body;
}

/**
 * Da de alta, confirma (como haría el backoffice) e inicia sesión un socio,
 * devolviendo un authToken usable — es el equivalente de test al flujo
 * completo apply -> backoffice confirma -> login que sigue la app.
 */
export async function createActiveMember(
  membershipURL: string,
  overrides: Partial<Member> & { passwordHash?: string } = {}
): Promise<{ authToken: string; member: Member }> {
  const { member, email, passwordHash } = await applyForMembership(membershipURL, overrides);
  const adminKey = process.env.ADMIN_API_KEY ?? "changeme-admin-key";
  await request(membershipURL)
    .post(`/v1/admin/members/${member.id}/confirm`)
    .set("x-admin-key", adminKey)
    .expect(200);
  return loginAsMember(membershipURL, email, passwordHash);
}

export function randomUUID(): string {
  return crypto.randomUUID();
}
