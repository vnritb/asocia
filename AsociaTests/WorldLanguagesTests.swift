import Testing
import Foundation
@testable import Asocia

@Suite("WorldLanguages")
struct WorldLanguagesTests {

    @Test("Los 5 primeros idiomas son español, catalán, gallego, euskera e inglés, en ese orden")
    func firstFiveAreSpainLanguagesPlusEnglish() {
        let languages = WorldLanguages.all()
        let firstFiveCodes = languages.prefix(5).map(\.code)
        #expect(firstFiveCodes == ["es", "ca", "gl", "eu", "en"])
    }

    @Test("Los siguientes 10 son los idiomas más hablados del mundo, sin repetir español/inglés")
    func nextTenArePopularLanguages() {
        let languages = WorldLanguages.all()
        let next10 = languages.dropFirst(5).prefix(10).map(\.code)
        #expect(next10.count == 10)
        #expect(!next10.contains("es"))
        #expect(!next10.contains("en"))
        #expect(Set(next10).isSubset(of: Set(WorldLanguages.priorityCodes)))
    }

    @Test("El resto de idiomas está ordenado alfabéticamente por nombre")
    func restIsAlphabetical() {
        let languages = WorldLanguages.all()
        let rest = Array(languages.dropFirst(15))
        let sortedNames = rest.map(\.name).sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
        #expect(rest.map(\.name) == sortedNames)
    }

    @Test("No hay códigos de idioma duplicados en toda la lista")
    func noDuplicateCodes() {
        let languages = WorldLanguages.all()
        let codes = languages.map(\.code)
        #expect(codes.count == Set(codes).count)
    }
}
