import Testing
import Foundation
@testable import Asocia

/// Tests unitaris amb Swift Testing (framework recomanat per Apple des de
/// Xcode 16 per a tests unitaris/d'integració nous; XCTest queda per als
/// UI tests — veure docs/ARQUITECTURA.md, secció Testing).
@Suite("MembershipStatus")
struct MembershipStatusTests {

    @Test("pendingApproval, active i rejected mostren la fitxa de soci", arguments: [
        (MembershipStatus.active, true),
        (MembershipStatus.pendingApproval, true),
        (MembershipStatus.rejected, true),
        (MembershipStatus.notMember, false)
    ])
    func showsMemberScreen(status: MembershipStatus, expected: Bool) {
        #expect(status.showsMemberScreen == expected)
    }

    @Test("Només active dona accés al Xat", arguments: [
        (MembershipStatus.active, true),
        (MembershipStatus.pendingApproval, false),
        (MembershipStatus.rejected, false),
        (MembershipStatus.notMember, false)
    ])
    func hasChatAccess(status: MembershipStatus, expected: Bool) {
        #expect(status.hasChatAccess == expected)
    }
}

@Suite("Member")
@MainActor
struct MemberTests {

    private func makeMember(syncStatus: SyncStatus = .synced) -> Member {
        Member(
            firstName: "Ana",
            firstSurname: "García",
            secondSurname: "López",
            email: "ana@example.com",
            mobilePhone: "600123456",
            address: "Carrer Major 1",
            postalCode: "08001",
            city: "Barcelona",
            province: "Barcelona",
            syncStatus: syncStatus
        )
    }

    @Test("markDirty marca pendingUpload i actualitza localUpdatedAt")
    func markDirtyUpdatesState() {
        let member = makeMember(syncStatus: .synced)
        let before = member.localUpdatedAt

        Thread.sleep(forTimeInterval: 0.01)
        member.markDirty()

        #expect(member.syncStatus == .pendingUpload)
        #expect(member.localUpdatedAt > before)
    }

    @Test("membershipStatus per defecte és notMember per a una alta recent")
    func defaultStatusIsNotMember() {
        let member = makeMember()
        #expect(member.membershipStatus == .notMember)
    }

    @Test("fullName combina nom i cognoms, ometent el 2n cognom si és buit")
    func fullNameOmitsEmptySecondSurname() {
        let member = Member(firstName: "Pol", firstSurname: "Vidal")
        #expect(member.fullName == "Pol Vidal")
    }

    @Test(
        "isValidApplication requereix nom, 1r cognom i almenys un contacte",
        arguments: [
            ("Ana", "García", "ana@example.com", "", "", true),
            ("Ana", "García", "", "600123456", "", true),
            ("Ana", "García", "", "", "931234567", true),
            ("Ana", "García", "", "", "", false),
            ("", "García", "ana@example.com", "", "", false),
            ("Ana", "", "ana@example.com", "", "", false)
        ]
    )
    func isValidApplication(firstName: String, firstSurname: String, email: String, mobile: String, landline: String, expected: Bool) {
        let result = Member.isValidApplication(
            firstName: firstName, firstSurname: firstSurname,
            email: email, mobilePhone: mobile, landlinePhone: landline
        )
        #expect(result == expected)
    }
}
