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

    @Test("Sólo hay 5 idiomas en la lista")
    func noDuplicateCodes() {
        #expect(WorldLanguages.all().count == 5)
    }
    
    
}
