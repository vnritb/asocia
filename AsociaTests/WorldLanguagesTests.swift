import Testing
import Foundation
@testable import Asocia

@Suite("WorldLanguages")
struct WorldLanguagesTests {

    @Test("Los 5 idiomas son español, catalán, gallego, euskera e inglés, en ese orden")
    func firstFiveAreSpainLanguagesPlusEnglish() {
        let languages = WorldLanguages.all()
        let firstFiveCodes = languages.prefix(5).map(\.code)
        #expect(firstFiveCodes == ["es", "ca", "gl", "eu", "en"])
        
    }
    
    //@Test("Sólo hay 5 idiomas")

    @Test("No hay códigos de idioma duplicados en toda la lista")
    func noDuplicateCodes() {
        let languages = WorldLanguages.all()
        let codes = languages.map(\.code)
        #expect(codes.count == Set(codes).count)
    }
    
    
}
