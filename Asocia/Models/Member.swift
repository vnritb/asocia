import Foundation
import SwiftData

/// Dades personals i d'alta del soci.
///
/// Viu a SwiftData (base de dades local al dispositiu). És l'única font de
/// veritat per a la UI: la pantalla de la fitxa SEMPRE llegeix d'aquí, mai
/// directament de la xarxa. `SyncEngine` és responsable de mantenir aquest
/// registre al dia amb el backend i de marcar `syncStatus` en conseqüència.
///
/// En aquest dispositiu només existeix (com a molt) un `Member`: el propi
/// titular del mòbil. `RootView` decideix quina pantalla mostrar en funció
/// de si existeix o no, i del seu `membershipStatus`.
@Model
final class Member {

    /// Identificador estable, generat al dispositiu en el moment de l'alta
    /// i usat com a clau primària també al backend.
    @Attribute(.unique) var id: UUID

    // Dades identificatives (obligatòries: firstName + firstSurname)
    var firstName: String
    var firstSurname: String
    var secondSurname: String

    // Contacte (obligatori almenys un de: email, mobilePhone, landlinePhone)
    var email: String
    var secondaryEmail: String
    var mobilePhone: String
    var landlinePhone: String

    // Adreça
    var address: String
    var postalCode: String
    var city: String
    var province: String

    // Dades personals i acadèmiques/professionals
    var birthDate: Date?
    var entryYear: String   // Curs/any d'entrada, p.ex. "2015/2016"
    var exitYear: String    // Curs/any de sortida
    var promotion: String   // Promoció
    var profession: String
    var workplace: String

    // Dades bancàries (per a una futura domiciliació de la quota anual)
    var iban: String

    // Xarxes socials (només el nom d'usuari/handle, sense la URL completa)
    var facebookUsername: String
    var instagramUsername: String
    var xUsername: String
    var tiktokUsername: String

    /// Fotografia del soci (JPEG comprimit). Emmagatzemada amb
    /// `.externalStorage` perquè SwiftData no infli les files de la taula
    /// amb el binari; SwiftData la guarda com a fitxer apart automàticament.
    @Attribute(.externalStorage) var photoData: Data?

    /// Consentiment explícit per aparèixer al cercador de socis del Chat
    /// ("cerca de persones xatejables"). Per defecte `false`: cal que el
    /// soci l'activi de forma expressa des de la seva fitxa.
    var isSearchable: Bool

    /// Identificador de l'associació a la qual pertany el soci. Encara no
    /// s'usa (el desplegable d'alta i el microservei de validació
    /// d'associacions són treball futur, veure docs/ARQUITECTURA.md), però
    /// l'atribut ja existeix perquè la cerca/visibilitat hi pugui dependre
    /// sense una migració posterior.
    var associationID: String?

    /// Si el soci vol ser visible per a socis d'ALTRES associacions quan
    /// aquests activin "veure totes les associacions" (funcionalitat futura,
    /// veure docs/ARQUITECTURA.md). Per defecte `false`.
    var isVisibleToOtherAssociations: Bool

    // Estat de l'alta
    var membershipStatusRaw: String
    var joinDate: Date?
    var rejectionReason: String?

    // Metadades de sincronització
    var syncStatusRaw: String
    var serverUpdatedAt: Date?
    var localUpdatedAt: Date

    var membershipStatus: MembershipStatus {
        get { MembershipStatus(rawValue: membershipStatusRaw) ?? .notMember }
        set { membershipStatusRaw = newValue.rawValue }
    }

    var syncStatus: SyncStatus {
        get { SyncStatus(rawValue: syncStatusRaw) ?? .pendingUpload }
        set { syncStatusRaw = newValue.rawValue }
    }

    var fullName: String {
        [firstName, firstSurname, secondSurname]
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .joined(separator: " ")
    }

    init(
        id: UUID = UUID(),
        firstName: String,
        firstSurname: String,
        secondSurname: String = "",
        email: String = "",
        secondaryEmail: String = "",
        mobilePhone: String = "",
        landlinePhone: String = "",
        address: String = "",
        postalCode: String = "",
        city: String = "",
        province: String = "",
        birthDate: Date? = nil,
        entryYear: String = "",
        exitYear: String = "",
        promotion: String = "",
        profession: String = "",
        workplace: String = "",
        iban: String = "",
        facebookUsername: String = "",
        instagramUsername: String = "",
        xUsername: String = "",
        tiktokUsername: String = "",
        photoData: Data? = nil,
        isSearchable: Bool = false,
        associationID: String? = nil,
        isVisibleToOtherAssociations: Bool = false,
        membershipStatus: MembershipStatus = .notMember,
        joinDate: Date? = nil,
        rejectionReason: String? = nil,
        syncStatus: SyncStatus = .pendingUpload,
        serverUpdatedAt: Date? = nil,
        localUpdatedAt: Date = .now
    ) {
        self.id = id
        self.firstName = firstName
        self.firstSurname = firstSurname
        self.secondSurname = secondSurname
        self.email = email
        self.secondaryEmail = secondaryEmail
        self.mobilePhone = mobilePhone
        self.landlinePhone = landlinePhone
        self.address = address
        self.postalCode = postalCode
        self.city = city
        self.province = province
        self.birthDate = birthDate
        self.entryYear = entryYear
        self.exitYear = exitYear
        self.promotion = promotion
        self.profession = profession
        self.workplace = workplace
        self.iban = iban
        self.facebookUsername = facebookUsername
        self.instagramUsername = instagramUsername
        self.xUsername = xUsername
        self.tiktokUsername = tiktokUsername
        self.photoData = photoData
        self.isSearchable = isSearchable
        self.associationID = associationID
        self.isVisibleToOtherAssociations = isVisibleToOtherAssociations
        self.membershipStatusRaw = membershipStatus.rawValue
        self.joinDate = joinDate
        self.rejectionReason = rejectionReason
        self.syncStatusRaw = syncStatus.rawValue
        self.serverUpdatedAt = serverUpdatedAt
        self.localUpdatedAt = localUpdatedAt
    }

    /// Marca el registre com modificat localment ara mateix i pendent de
    /// pujar. Cridar sempre que la UI editi un camp.
    func markDirty() {
        localUpdatedAt = .now
        syncStatus = .pendingUpload
    }

    /// Compleix el mínim per enviar la sol·licitud d'alta: nom, primer
    /// cognom, i almenys una via de contacte.
    static func isValidApplication(
        firstName: String, firstSurname: String,
        email: String, mobilePhone: String, landlinePhone: String
    ) -> Bool {
        let hasContact = !email.trimmingCharacters(in: .whitespaces).isEmpty
            || !mobilePhone.trimmingCharacters(in: .whitespaces).isEmpty
            || !landlinePhone.trimmingCharacters(in: .whitespaces).isEmpty
        return !firstName.trimmingCharacters(in: .whitespaces).isEmpty
            && !firstSurname.trimmingCharacters(in: .whitespaces).isEmpty
            && hasContact
    }
}
