import Foundation

/// Traducción "de mentira" para `AppEnvironment.mock`: no llama a ningún
/// servicio de IA, simplemente antepone el código de idioma a cada texto
/// (p.ex. "[fr] Hola") para que sea evidente, mientras se desarrolla, que
/// el idioma ha cambiado — sin depender de `translation-service` ni de una
/// clave de Anthropic.
actor MockTranslationClient: TranslationServicing {
    func translate(strings: [String: String], to languageCode: String) async throws -> [String: String] {
        try? await Task.sleep(for: .milliseconds(400)) // simula la latencia de una traducción real
        return strings.mapValues { "[\(languageCode)] \($0)" }
    }
}
