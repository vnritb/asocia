/**
 * Contratos de datos compartidos por TODOS los microservicios y por CUALQUIER
 * cliente (la app iOS de este repo, y la futura app Android, que consumirá
 * exactamente estos mismos endpoints y formas de JSON).
 *
 * Los nombres de campo están escritos tal cual los serializa `JSONEncoder`
 * en Swift para los DTOs de la app iOS (ver Asocia/Services/APIClient.swift
 * y Asocia/Models/ChatModels.swift) — incluyendo mayúsculas como en
 * `participantIDs` o `conversationID` — para que el JSON sea intercambiable
 * sin capas de traducción entre cliente y servidor.
 */

export type MembershipStatus = "pendingApproval" | "active" | "rejected";

export interface Member {
  id: string;
  firstName: string;
  firstSurname: string;
  secondSurname: string;
  email: string;
  secondaryEmail: string;
  mobilePhone: string;
  landlinePhone: string;
  address: string;
  postalCode: string;
  city: string;
  province: string;
  /** ISO 8601, o null si no se indicó. */
  birthDate: string | null;
  entryYear: string;
  exitYear: string;
  promotion: string;
  profession: string;
  workplace: string;
  iban: string;
  /** Solo el nombre de usuario/handle, sin la URL completa. */
  facebookUsername: string;
  instagramUsername: string;
  xUsername: string;
  tiktokUsername: string;
  /**
   * De momento, igual que en el cliente iOS, la foto viaja como JPEG en
   * base64 dentro del propio JSON (ver nota en Asocia/Services/APIClient.swift).
   * Para producción real se recomienda migrar a `photoUrl` apuntando a un
   * bucket de objetos (Cloudflare R2 / S3-compatible) — ver docs/ARQUITECTURA.md.
   */
  photoBase64: string | null;
  /** Consentimiento explícito para aparecer en la búsqueda de socios del Chat. */
  isSearchable: boolean;
  /**
   * Asociación a la que pertenece el socio. Todavía sin UI ni microservicio
   * de validación (roadmap, ver docs/ARQUITECTURA.md secc. "Multi-asociación
   * y backoffice de administradores") — el atributo ya existe para no
   * necesitar una migración de datos cuando se construya.
   */
  associationID: string | null;
  /** Visible para socios de OTRAS asociaciones que activen "ver todas" (roadmap). */
  isVisibleToOtherAssociations: boolean;
  membershipStatus: MembershipStatus;
  joinDate: string | null;
  rejectionReason: string | null;
  updatedAt: string;
}

/** Campos que puede editar el propio socio desde la app (PATCH /v1/members/me). */
export const MEMBER_EDITABLE_FIELDS = [
  "firstName",
  "firstSurname",
  "secondSurname",
  "email",
  "secondaryEmail",
  "mobilePhone",
  "landlinePhone",
  "address",
  "postalCode",
  "city",
  "province",
  "birthDate",
  "entryYear",
  "exitYear",
  "promotion",
  "profession",
  "workplace",
  "iban",
  "facebookUsername",
  "instagramUsername",
  "xUsername",
  "tiktokUsername",
  "photoBase64",
  "isSearchable",
  "isVisibleToOtherAssociations"
] as const;

export interface MembershipApplicationResponse {
  authToken: string;
  member: Member;
}

export type ConversationKind = "individual" | "group" | "activity";

export interface Conversation {
  id: string;
  kind: ConversationKind;
  title: string;
  participantIDs: string[];
  lastMessagePreview: string;
  lastMessageAt: string | null;
  /** Solo se usa en salas "activity" (listado "Todas las actividades"). */
  photoData: string | null;
}

/** Resumen para GET /v1/conversations/activities — ver ActivitySummary en la app iOS. */
export interface ActivitySummary {
  conversation: Conversation;
  isParticipant: boolean;
  nextEventDate: string | null;
}

export interface ChatMessage {
  id: string;
  conversationID: string;
  senderID: string;
  senderName: string;
  text: string;
  sentAt: string;
}

export type EventAttendeeStatus = "invited" | "confirmed";

export interface EventAttendee {
  id: string;
  name: string;
  status: EventAttendeeStatus;
}

export interface ActivityEvent {
  id: string;
  conversationID: string;
  title: string;
  eventDescription: string;
  startDate: string;
  endDate: string | null;
  location: string;
  attendees: EventAttendee[];
}

export interface ChatUser {
  id: string;
  fullName: string;
  photoData: string | null; // base64, mismo criterio que Member.photoBase64
}

export interface TranslateRequest {
  targetLanguage: string;
  strings: Record<string, string>;
}

export interface TranslateResponse {
  strings: Record<string, string>;
}
