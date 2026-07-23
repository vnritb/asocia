import Foundation
import Network
import SwiftData
import os.log

/// Motor de sincronització offline-first entre SwiftData (local) i el
/// backend de microserveis.
///
/// Regles:
/// - La UI SEMPRE llegeix de SwiftData. Mai espera la xarxa per pintar res.
/// - Qualsevol edició local marca `member.syncStatus = .pendingUpload`
///   immediatament (via `Member.markDirty()`), de forma síncrona.
/// - `SyncEngine` puja el pendent i baixa l'últim del servidor en quant hi
///   ha connexió (`NWPathMonitor`), en obrir l'app i cada `syncInterval`.
/// - Resolució de conflictes: "servidor guanya" per a `membershipStatus`
///   (només el backend pot confirmar/rebutjar una alta), però per a les
///   dades personals editables per l'usuari guanya la versió amb
///   `updatedAt` més recent ("last write wins").
@MainActor
@Observable
final class SyncEngine {

    private static let logger = Logger(subsystem: "org.itb.asocia", category: "Sync")

    private let apiClient: MembershipAPIClient
    private let modelContext: ModelContext
    private let pathMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "org.itb.asocia.network-monitor")

    private(set) var isOnline = false
    private(set) var isSyncing = false
    private(set) var lastSyncError: String?
    private(set) var lastSyncedAt: Date?

    private var syncTask: Task<Void, Never>?
    private let syncInterval: TimeInterval = 60 * 5 // 5 minuts

    init(apiClient: MembershipAPIClient, modelContext: ModelContext) {
        self.apiClient = apiClient
        self.modelContext = modelContext
    }

    /// Arrenca el monitor de xarxa i el bucle de sincronització periòdica.
    /// Cridar una vegada des d'`AsociaApp` en arrencar.
    func start() {
        pathMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                guard let self else { return }
                let wasOffline = !self.isOnline
                self.isOnline = path.status == .satisfied
                if wasOffline, self.isOnline {
                    await self.syncNow()
                }
            }
        }
        pathMonitor.start(queue: monitorQueue)

        syncTask?.cancel()
        syncTask = Task { [weak self] in
            while let self, !Task.isCancelled {
                await self.syncNow()
                try? await Task.sleep(for: .seconds(self.syncInterval))
            }
        }
    }

    func stop() {
        pathMonitor.cancel()
        syncTask?.cancel()
    }

    // MARK: - Sincronització

    /// Puja canvis pendents i baixa l'últim estat del servidor. seguro de
    /// cridar repetidament (p.ex. en passar a primer pla).
    func syncNow() async {
        guard !isSyncing else { return }
        isSyncing = true
        lastSyncError = nil
        defer { isSyncing = false }

        do {
            try await pushPendingChanges()
            try await pullLatestFromServer()
            lastSyncedAt = .now
        } catch {
            Self.logger.error("Fallo de sincronización: \(error.localizedDescription)")
            lastSyncError = error.localizedDescription
            await markCurrentMemberSyncFailed()
        }
    }

    private func pushPendingChanges() async throws {
        let descriptor = FetchDescriptor<Member>(
            predicate: #Predicate { $0.syncStatusRaw == "pendingUpload" }
        )
        let pending = try modelContext.fetch(descriptor)
        guard !pending.isEmpty else { return }

        for member in pending {
            let dto = member.asDTO()
            let updated = try await apiClient.updateMember(dto)
            member.apply(dto: updated)
            member.syncStatus = .synced
        }
        try modelContext.save()
    }

    private func pullLatestFromServer() async throws {
        let remote = try await apiClient.fetchCurrentMember()

        let descriptor = FetchDescriptor<Member>(
            predicate: #Predicate { $0.id == remote.id }
        )
        if let local = try modelContext.fetch(descriptor).first {
            resolveConflict(local: local, remote: remote)
        } else {
            let member = Member(id: remote.id, firstName: remote.firstName, firstSurname: remote.firstSurname)
            member.apply(dto: remote)
            member.syncStatus = .synced
            modelContext.insert(member)
        }
        try modelContext.save()
    }

    /// "Servidor guanya" en `membershipStatus` (només el backend decideix
    /// altes/rebutjos). A la resta de camps, guanya qui tingui
    /// `updatedAt` més recent, per no perdre edicions offline de l'usuari.
    private func resolveConflict(local: Member, remote: MemberDTO) {
        local.membershipStatus = remote.membershipStatus
        local.joinDate = remote.joinDate
        local.rejectionReason = remote.rejectionReason

        if local.syncStatus == .pendingUpload, local.localUpdatedAt > remote.updatedAt {
            // L'usuari ha editat dades personals sense connexió després de
            // l'última foto coneguda del servidor: mantenim el local i
            // deixem que el següent `pushPendingChanges` ho pugi.
            return
        }

        local.apply(dto: remote)
        local.syncStatus = .synced
    }

    private func markCurrentMemberSyncFailed() async {
        let descriptor = FetchDescriptor<Member>()
        guard let members = try? modelContext.fetch(descriptor) else { return }
        for member in members where member.syncStatus == .pendingUpload {
            member.syncStatus = .syncFailed
        }
        try? modelContext.save()
    }
}

private extension Member {
    func asDTO() -> MemberDTO {
        MemberDTO(
            id: id, firstName: firstName, firstSurname: firstSurname, secondSurname: secondSurname,
            email: email, secondaryEmail: secondaryEmail, mobilePhone: mobilePhone, landlinePhone: landlinePhone,
            address: address, postalCode: postalCode, city: city, province: province,
            birthDate: birthDate, entryYear: entryYear, exitYear: exitYear, promotion: promotion,
            profession: profession, workplace: workplace, iban: iban,
            facebookUsername: facebookUsername, instagramUsername: instagramUsername,
            xUsername: xUsername, tiktokUsername: tiktokUsername,
            photoBase64: photoData?.base64EncodedString(),
            isSearchable: isSearchable, associationID: associationID,
            isVisibleToOtherAssociations: isVisibleToOtherAssociations,
            membershipStatus: membershipStatus, joinDate: joinDate, rejectionReason: rejectionReason,
            updatedAt: localUpdatedAt
        )
    }

    func apply(dto: MemberDTO) {
        firstName = dto.firstName
        firstSurname = dto.firstSurname
        secondSurname = dto.secondSurname
        email = dto.email
        secondaryEmail = dto.secondaryEmail
        mobilePhone = dto.mobilePhone
        landlinePhone = dto.landlinePhone
        address = dto.address
        postalCode = dto.postalCode
        city = dto.city
        province = dto.province
        birthDate = dto.birthDate
        entryYear = dto.entryYear
        exitYear = dto.exitYear
        promotion = dto.promotion
        profession = dto.profession
        workplace = dto.workplace
        iban = dto.iban
        facebookUsername = dto.facebookUsername
        instagramUsername = dto.instagramUsername
        xUsername = dto.xUsername
        tiktokUsername = dto.tiktokUsername
        if let photoBase64 = dto.photoBase64, let data = Data(base64Encoded: photoBase64) {
            photoData = data
        }
        isSearchable = dto.isSearchable
        associationID = dto.associationID
        isVisibleToOtherAssociations = dto.isVisibleToOtherAssociations
        membershipStatus = dto.membershipStatus
        joinDate = dto.joinDate
        rejectionReason = dto.rejectionReason
        serverUpdatedAt = dto.updatedAt
    }
}
