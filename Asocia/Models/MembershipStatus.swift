import Foundation

/// Estat de l'alta de soci.
///
/// Cicle de vida (sense pagament, l'alta es confirma a mà des de l'aplicació
/// de gestió — "backoffice"):
/// `notMember` -> (formulari d'alta) -> `pendingApproval` -> `active`
/// L'equip gestor també pot rebutjar una alta (duplicat, dades errònies): `rejected`.
enum MembershipStatus: String, Codable, CaseIterable, Sendable {

    /// No hi ha cap sol·licitud local. Es mostra el botó "Asocia".
    case notMember

    /// L'usuari ha enviat el formulari, però l'equip gestor encara no l'ha
    /// confirmat a mà des del backoffice. Es mostra un indicador provisional.
    case pendingApproval

    /// L'equip gestor ha confirmat l'alta. L'indicador provisional
    /// desapareix i s'habilita l'accés al Xat.
    case active

    /// L'equip gestor ha rebutjat la sol·licitud (p.ex. dades duplicades).
    case rejected

    /// Si és true, l'app mostra la fitxa de dades del soci (encara que
    /// estigui pendent de confirmar); si és false, mostra el botó "Asocia".
    var showsMemberScreen: Bool {
        switch self {
        case .active, .pendingApproval, .rejected:
            return true
        case .notMember:
            return false
        }
    }

    /// Només els socis amb l'alta confirmada tenen accés al Xat.
    var hasChatAccess: Bool {
        self == .active
    }
}
