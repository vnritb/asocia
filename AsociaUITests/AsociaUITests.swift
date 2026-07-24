import XCTest

/// Tests de UI amb XCUITest (XCTest continua sent el framework recomanat
/// per Apple per a automatització de UI el 2026; Swift Testing només cobreix
/// unit/integration tests — veure docs/ARQUITECTURA.md, secció Testing).
@MainActor
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

        // En modo UI test no hay splash, el botón aparece inmediatamente
        let asociaButton = app.buttons["Asocia"]
        XCTAssertTrue(asociaButton.waitForExistence(timeout: 3), "El botón Asocia no apareció")
    }

    /// Tocar el botó obre el formulari d'alta amb els camps obligatoris,
    /// sense cap pas de pagament.
    func testTappingAsociaOpensSignupForm() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-UITEST_RESET_STATE", "YES"]
        app.launch()

        // En modo UI test no hay splash
        let asociaButton = app.buttons["Asocia"]
        XCTAssertTrue(asociaButton.waitForExistence(timeout: 3), "El botón Asocia no apareció")
        
        // Asegurarse de que es hittable
        XCTAssertTrue(asociaButton.isHittable, "El botón Asocia no es tappable")
        
        // Hacer tap en el centro de la pantalla (el botón ocupa toda la pantalla)
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()

        // Dar tiempo a la animación del fullScreenCover
        sleep(2)
        
        // Verificar que existen los campos obligatorios
        let nameField = app.textFields["signup_firstName"]
        if !nameField.exists {
            // Debug: imprimir jerarquía para ver qué hay
            print("❌ El formulario no se abrió. Jerarquía actual:")
            print(app.debugDescription)
        }
        XCTAssertTrue(nameField.waitForExistence(timeout: 5), "El campo de nombre no apareció")
        
        let surnameField = app.textFields["signup_firstSurname"]
        XCTAssertTrue(surnameField.exists, "El campo de apellido no existe")

        // El botón de enviar está al final del formulario, hacer scroll hacia abajo
        let submitButton = app.buttons["signup_submitButton"]
        
        // Hacer scroll múltiple hasta que el botón sea visible (máximo 10 intentos)
        var scrollAttempts = 0
        while !submitButton.exists && scrollAttempts < 10 {
            app.swipeUp()
            scrollAttempts += 1
            Thread.sleep(forTimeInterval: 0.5)
        }
        
        XCTAssertTrue(submitButton.waitForExistence(timeout: 3), "El botón de enviar no apareció después de \(scrollAttempts) scrolls")
        XCTAssertFalse(submitButton.isEnabled, "El botón debería estar deshabilitado")
    }

    /// Al rellenar los campos obligatorios (nombre, apellido y un contacto),
    /// el botón de enviar la solicitud se habilita.
    func testFormEnablesSubmitOnceRequiredFieldsAreFilled() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-UITEST_RESET_STATE", "YES"]
        app.launch()

        // En modo UI test no hay splash
        let asociaButton = app.buttons["Asocia"]
        XCTAssertTrue(asociaButton.waitForExistence(timeout: 3), "El botón Asocia no apareció")
        XCTAssertTrue(asociaButton.isHittable, "El botón Asocia no es tappable")
        
        // Hacer tap en el centro de la pantalla
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()

        // Dar tiempo a la animación del fullScreenCover
        sleep(2)

        let nameField = app.textFields["signup_firstName"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5), "El campo de nombre no apareció")
        nameField.tap()
        nameField.typeText("Ana")

        let surnameField = app.textFields["signup_firstSurname"]
        XCTAssertTrue(surnameField.exists, "El campo de apellido no existe")
        surnameField.tap()
        surnameField.typeText("García")
        
        let emailField = app.textFields["signup_email"]
        emailField.tap()
        emailField.typeText("ana@example.com")

        let mobileField = app.textFields["signup_mobilePhone"]
        XCTAssertTrue(mobileField.exists, "El campo de móvil no existe")
        mobileField.tap()
        mobileField.typeText("600123456")

        // ⚠️ IMPORTANTE: Cerrar el teclado antes de hacer scroll
        // Tocar fuera del campo de texto para que el teclado se cierre
        app.tap()
        sleep(1)

        // Esperar un momento para que la validación se ejecute
        sleep(1)

        // El botón de enviar está al final del formulario, hacer scroll hacia abajo
        let submitButton = app.buttons["signup_submitButton"]
        
        // Hacer scroll múltiple hasta que el botón sea visible (máximo 10 intentos)
        var scrollAttempts = 0
        while !submitButton.exists && scrollAttempts < 20 {
            app.swipeUp()
            scrollAttempts += 1
            Thread.sleep(forTimeInterval: 0.5)
        }
        
        XCTAssertTrue(submitButton.exists, "El botón de enviar no existe después de \(scrollAttempts) scrolls")
        XCTAssertTrue(submitButton.isEnabled, "El botón debería estar habilitado después de llenar los campos obligatorios")
    }
    
    /// Test del flujo completo: enviar el formulario, verificar estado pendiente,
    /// y confirmar que después de la aprobación (automática en mock) el usuario
    /// tiene acceso al chat.
    func testCompleteSignupFlowWithMockApproval() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-UITEST_RESET_STATE", "YES"]
        app.launch()

        // 1. Abrir el formulario de alta
        let asociaButton = app.buttons["Asocia"]
        XCTAssertTrue(asociaButton.waitForExistence(timeout: 3), "El botón Asocia no apareció")
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        sleep(2)

        // 2. Rellenar campos obligatorios
        let nameField = app.textFields["signup_firstName"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5), "El campo de nombre no apareció")
        nameField.tap()
        nameField.typeText("Ana")

        let surnameField = app.textFields["signup_firstSurname"]
        surnameField.tap()
        surnameField.typeText("García")

        let emailField = app.textFields["signup_email"]
        emailField.tap()
        emailField.typeText("ana@example.com")

        // ⚠️ Cerrar el teclado antes de hacer scroll
        app.tap()
        sleep(1)

        // 3. Hacer scroll hasta el botón de enviar
        var scrollAttempts = 0
        let submitButton = app.buttons["signup_submitButton"]
        while !submitButton.exists && scrollAttempts < 10 {
            app.swipeUp()
            scrollAttempts += 1
            Thread.sleep(forTimeInterval: 0.5)
        }

        // 4. Verificar que el botón está habilitado y pulsarlo
        XCTAssertTrue(submitButton.exists, "El botón de enviar no existe")
        XCTAssertTrue(submitButton.isEnabled, "El botón debería estar habilitado")
        submitButton.tap()

        // 5. Esperar a que se cierre el formulario y aparezca la pantalla de perfil
        sleep(3)

        // 6. Verificar que aparece el indicador de "Pendiente de aprobación"
        // El texto puede variar según la localización, así que buscamos el icono de reloj
        let pendingIndicator = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'pendiente' OR label CONTAINS[c] 'pending' OR label CONTAINS[c] 'aprovació'")).firstMatch
        XCTAssertTrue(pendingIndicator.waitForExistence(timeout: 5), "No apareció el indicador de pendiente de aprobación")

        // 7. Verificar que NO hay acceso al Chat todavía (no debe haber TabBar con Chat)
        let chatTab = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'chat'")).firstMatch
        XCTAssertFalse(chatTab.exists, "El chat NO debería ser accesible mientras el estado es pendiente")

        // 8. En modo mock, después de 8 segundos el estado cambia automáticamente a "active"
        // Pero necesitamos sincronizar manualmente para que la app lo detecte
        print("⏳ Esperando 8 segundos para que el mock cambie el estado...")
        sleep(8)
        
        // 9. Hacer scroll hasta encontrar el botón "Sincronizar ahora"
        let syncNowButton = app.buttons["profile_syncNowButton"]
        
        var syncScrollAttempts = 0
        while !syncNowButton.exists && syncScrollAttempts < 10 {
            app.swipeUp() // Scroll hacia abajo en la vista de perfil
            syncScrollAttempts += 1
            Thread.sleep(forTimeInterval: 0.5)
        }
        
        XCTAssertTrue(syncNowButton.exists, "No se encontró el botón de sincronizar después de \(syncScrollAttempts) scrolls")
        
        // 10. Pulsar el botón de sincronizar para que descargue el nuevo estado "active"
        syncNowButton.tap()
        sleep(2)

        // 11. Verificar que el indicador de pendiente desapareció
        XCTAssertFalse(pendingIndicator.exists, "El indicador de pendiente debería haber desaparecido después de la sincronización")

        // 12. Verificar que ahora SÍ hay acceso al Chat (TabBar visible)
        let chatTabAfterApproval = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'chat'")).firstMatch
        XCTAssertTrue(chatTabAfterApproval.waitForExistence(timeout: 5), "El chat debería ser accesible después de la aprobación")
        
        print("✅ Test completo: Alta enviada → Estado pendiente → Sincronización manual → Acceso al chat")
    }
    
    /// Test de la funcionalidad de aprobación manual desde Ajustes (solo en modo mock)
    func testManualApprovalFromSettings() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-UITEST_RESET_STATE", "YES"]
        app.launch()

        // 1. Crear un usuario pendiente (mismo flujo que el test anterior)
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        sleep(2)

        let nameField = app.textFields["signup_firstName"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText("Pedro")

        let surnameField = app.textFields["signup_firstSurname"]
        surnameField.tap()
        surnameField.typeText("López")

        let emailField = app.textFields["signup_email"]
        emailField.tap()
        emailField.typeText("pedro@example.com")

        // ⚠️ Cerrar el teclado antes de hacer scroll
        app.tap()
        sleep(1)

        // Scroll hasta el botón de enviar
        var scrollAttempts = 0
        let submitButton = app.buttons["signup_submitButton"]
        while !submitButton.exists && scrollAttempts < 20 {
            app.swipeUp()
            scrollAttempts += 1
            Thread.sleep(forTimeInterval: 0.5)
        }
        
        submitButton.tap()
        sleep(2)

        // 2. Verificar estado pendiente
        let pendingIndicator = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'pendiente' OR label CONTAINS[c] 'pending'")).firstMatch
        XCTAssertTrue(pendingIndicator.waitForExistence(timeout: 5), "Debería aparecer estado pendiente")

        // 3. Ir a Ajustes
        let settingsButton = app.buttons["profile_settingsButton"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 3), "No se encontró el botón de ajustes en el toolbar")
        settingsButton.tap()

        sleep(1)

        // 4. Buscar la sección de simulación de alta (solo en modo mock)
        let approveButton = app.buttons["Confirmar Alta"]
        XCTAssertTrue(approveButton.waitForExistence(timeout: 5), "No se encontró el botón de Confirmar Alta en modo mock")

        // 5. Pulsar el botón de confirmar
        approveButton.tap()
        sleep(1)

        // 6. Cerrar el alert de confirmación si aparece
        let okButton = app.buttons.matching(NSPredicate(format: "label == 'OK' OR label == 'Aceptar'")).firstMatch
        if okButton.exists {
            okButton.tap()
        }

        // 7. Volver a la pantalla de perfil
        if app.navigationBars.buttons["Back"].exists {
            app.navigationBars.buttons["Back"].tap()
        } else if app.buttons["Cerrar"].exists {
            app.buttons["Cerrar"].tap()
        }
        
        sleep(1)

        // 8. Verificar que ahora hay acceso al chat
        let chatTab = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'chat'")).firstMatch
        XCTAssertTrue(chatTab.waitForExistence(timeout: 5), "Debería haber acceso al chat después de la aprobación manual")
        
        print("✅ Test de aprobación manual desde ajustes completado")
    }
}
