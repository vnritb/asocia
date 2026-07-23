import XCTest

/// Tests de UI amb XCUITest (XCTest continua sent el framework recomanat
/// per Apple per a automatització de UI el 2026; Swift Testing només cobreix
/// unit/integration tests — veure docs/ARQUITECTURA.md, secció Testing).
final class AsociaUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Sense soci donat d'alta, l'app ha de mostrar el botó "Asocia" a
    /// pantalla completa just després del splash.
    func testShowsAsociaButtonWhenNotAMember() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-UITEST_RESET_STATE", "YES"]
        app.launch()

        let asociaButton = app.buttons["Asocia"]
        XCTAssertTrue(asociaButton.waitForExistence(timeout: 5))
    }

    /// Tocar el botó obre el formulari d'alta amb els camps obligatoris,
    /// sense cap pas de pagament.
    func testTappingAsociaOpensSignupForm() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-UITEST_RESET_STATE", "YES"]
        app.launch()

        let asociaButton = app.buttons["Asocia"]
        XCTAssertTrue(asociaButton.waitForExistence(timeout: 5))
        asociaButton.tap()

        XCTAssertTrue(app.navigationBars["Hazte socio"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.textFields["Nombre *"].exists)
        XCTAssertTrue(app.textFields["1er apellido *"].exists)

        // El botón de enviar empieza deshabilitado hasta rellenar nombre + apellido + contacto.
        let submitButton = app.buttons["Enviar solicitud de alta"]
        XCTAssertTrue(submitButton.exists)
        XCTAssertFalse(submitButton.isEnabled)
    }

    /// Al rellenar los campos obligatorios (nombre, apellido y un contacto),
    /// el botón de enviar la solicitud se habilita.
    func testFormEnablesSubmitOnceRequiredFieldsAreFilled() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-UITEST_RESET_STATE", "YES"]
        app.launch()

        app.buttons["Asocia"].tap()

        let nameField = app.textFields["Nombre *"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText("Ana")

        app.textFields["1er apellido *"].tap()
        app.textFields["1er apellido *"].typeText("García")

        app.textFields["Móvil"].tap()
        app.textFields["Móvil"].typeText("600123456")

        XCTAssertTrue(app.buttons["Enviar solicitud de alta"].isEnabled)
    }
}
