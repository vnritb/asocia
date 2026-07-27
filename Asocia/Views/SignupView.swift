import SwiftUI
import SwiftData

/// Formulario de alta de nuevo socio (sin pago).
///
/// Orden de operaciones (ver docs/ARQUITECTURA.md):
/// 1. Validar el formulario: nombre + primer apellido, email y contraseña.
/// 2. Enviar la solicitud al backend (`authService.register`),
///    que crea el registro en estado `pendingApproval` y devuelve un token de sesión.
/// 3. Guardar el `Member` resultante en SwiftData (local, offline-first) y
///    cerrar el formulario; `RootView` pasa automáticamente a mostrar la
///    ficha del socio con el aviso de "pendiente de confirmar".
/// 4. Más adelante, el equipo gestor confirma o rechaza el alta desde el
///    backoffice; al confirmarla, el indicador provisional desaparece y se
///    habilita el acceso al Chat.
struct SignupView: View {
    @Environment(\.authService) private var authService
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(LocalizationManager.self) private var loc
    
    let onSuccess: () -> Void

    @State private var photoData: Data?

    @State private var firstName = ""
    @State private var firstSurname = ""
    @State private var secondSurname = ""

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var secondaryEmail = ""
    @State private var mobilePhone = ""
    @State private var landlinePhone = ""

    @State private var address = ""
    @State private var postalCode = ""
    @State private var city = ""
    @State private var province = ""

    @State private var birthDate: Date?
    @State private var hasBirthDate = false
    @State private var entryYear = ""
    @State private var exitYear = ""
    @State private var promotion = ""
    @State private var profession = ""
    @State private var workplace = ""
    @State private var iban = ""

    @State private var facebookUsername = ""
    @State private var instagramUsername = ""
    @State private var xUsername = ""
    @State private var tiktokUsername = ""

    @State private var isSearchable = false

    @State private var isProcessing = false
    @State private var errorMessage: String?

    private var isFormValid: Bool {
        let hasFirstName = !firstName.trimmingCharacters(in: .whitespaces).isEmpty
        let hasFirstSurname = !firstSurname.trimmingCharacters(in: .whitespaces).isEmpty
        let hasEmail = !email.trimmingCharacters(in: .whitespaces).isEmpty
        let hasPassword = !password.isEmpty
        let passwordsMatch = password == confirmPassword
        let passwordLongEnough = password.count >= 6
        
        #if DEBUG
        if !hasFirstName { print("❌ Falta nombre") }
        if !hasFirstSurname { print("❌ Falta primer apellido") }
        if !hasEmail { print("❌ Falta email") }
        if !hasPassword { print("❌ Falta contraseña") }
        if !passwordsMatch { print("❌ Las contraseñas no coinciden: '\(password)' vs '\(confirmPassword)'") }
        if !passwordLongEnough { print("❌ Contraseña muy corta: \(password.count) caracteres (mínimo 6)") }
        #endif
        
        return hasFirstName && hasFirstSurname && hasEmail && hasPassword && passwordsMatch && passwordLongEnough
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        MemberPhotoPicker(photoData: $photoData)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }

                Section {
                    TextField(loc.t("signup.field.firstName"), text: $firstName)
                        .textContentType(.givenName)
                        .accessibilityIdentifier("signup_firstName")
                    TextField(loc.t("signup.field.firstSurname"), text: $firstSurname)
                        .textContentType(.familyName)
                        .accessibilityIdentifier("signup_firstSurname")
                    TextField(loc.t("signup.field.secondSurname"), text: $secondSurname)
                        .textContentType(.familyName)
                        .accessibilityIdentifier("signup_secondSurname")
                    Toggle(loc.t("signup.field.birthDateToggle"), isOn: $hasBirthDate.animation())
                    if hasBirthDate {
                        DatePicker(
                            loc.t("signup.field.birthDate"),
                            selection: Binding(
                                get: { birthDate ?? Calendar.current.date(byAdding: .year, value: -25, to: .now) ?? .now },
                                set: { birthDate = $0 }
                            ),
                            displayedComponents: .date
                        )
                    }
                } footer: {
                    Text(loc.t("signup.requiredFieldsFooter"))
                }

                Section {
                    TextField(loc.t("signup.field.email"), text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .accessibilityIdentifier("signup_email")
                    
                    SecureField(loc.t("signup.field.password"), text: $password)
                        .textContentType(.newPassword)
                        .accessibilityIdentifier("signup_password")
                    
                    SecureField(loc.t("signup.field.confirmPassword"), text: $confirmPassword)
                        .textContentType(.newPassword)
                        .accessibilityIdentifier("signup_confirmPassword")
                    
                    // Indicadores de validación de contraseña
                    if !password.isEmpty {
                        ValidationRow(
                            text: "Mínimo 6 caracteres",
                            isValid: password.count >= 6
                        )
                    }
                    
                    if !password.isEmpty && !confirmPassword.isEmpty {
                        ValidationRow(
                            text: "Las contraseñas coinciden",
                            isValid: password == confirmPassword
                        )
                    }
                    
                    TextField(loc.t("signup.field.email2"), text: $secondaryEmail)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .accessibilityIdentifier("signup_email2")
                    TextField(loc.t("signup.field.mobilePhone"), text: $mobilePhone)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                        .accessibilityIdentifier("signup_mobilePhone")
                    TextField(loc.t("signup.field.landlinePhone"), text: $landlinePhone)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                        .accessibilityIdentifier("signup_landlinePhone")
                } footer: {
                    Text(loc.t("signup.contactFooter"))
                }

                Section(loc.t("signup.section.address")) {
                    TextField(loc.t("signup.field.address"), text: $address)
                        .textContentType(.fullStreetAddress)
                    TextField(loc.t("signup.field.postalCode"), text: $postalCode)
                        .textContentType(.postalCode)
                        .keyboardType(.numberPad)
                    TextField(loc.t("signup.field.city"), text: $city)
                        .textContentType(.addressCity)
                    TextField(loc.t("signup.field.province"), text: $province)
                        .textContentType(.addressState)
                }

                Section(loc.t("signup.section.academic")) {
                    TextField(loc.t("signup.field.entryYear"), text: $entryYear)
                    TextField(loc.t("signup.field.exitYear"), text: $exitYear)
                    TextField(loc.t("signup.field.promotion"), text: $promotion)
                    TextField(loc.t("signup.field.profession"), text: $profession)
                    TextField(loc.t("signup.field.workplace"), text: $workplace)
                }

                Section {
                    TextField(loc.t("signup.field.iban"), text: $iban)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                } header: {
                    Text(loc.t("signup.section.bank"))
                } footer: {
                    Text(loc.t("signup.bankFooter"))
                }

                Section(loc.t("signup.section.social")) {
                    TextField(loc.t("signup.field.facebook"), text: $facebookUsername)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField(loc.t("signup.field.instagram"), text: $instagramUsername)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField(loc.t("signup.field.x"), text: $xUsername)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField(loc.t("signup.field.tiktok"), text: $tiktokUsername)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section {
                    Toggle(loc.t("signup.field.isSearchable"), isOn: $isSearchable)
                } footer: {
                    Text(loc.t("signup.searchableFooter"))
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    Button {
                        Task { await submit() }
                    } label: {
                        if isProcessing {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text(loc.t("signup.submit"))
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(!isFormValid || isProcessing)
                    .accessibilityIdentifier("signup_submitButton")
                } footer: {
                    if !isFormValid && !isProcessing {
                        Text("Completa los campos obligatorios: nombre, primer apellido, email y contraseña (mínimo 6 caracteres)")
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle(loc.t("signup.navTitle"))
            .navigationBarTitleDisplayMode(.inline)
            .accessibilityIdentifier("signup_form")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(loc.t("common.cancel")) { dismiss() }
                        .disabled(isProcessing)
                }
            }
        }
    }

    private func submit() async {
        isProcessing = true
        errorMessage = nil
        defer { isProcessing = false }

        do {
            let localID = UUID()
            
            // Registrar usuario en el backend de autenticación
            let response = try await authService.register(
                id: localID,
                email: email,
                password: password,
                firstName: firstName,
                firstSurname: firstSurname
            )

            // Crear member local con todos los datos del formulario
            let passwordHash = AuthService.hashPassword(password)
            let member = Member(
                id: localID,
                firstName: firstName,
                firstSurname: firstSurname,
                secondSurname: secondSurname,
                email: email,
                secondaryEmail: secondaryEmail,
                mobilePhone: mobilePhone,
                landlinePhone: landlinePhone,
                passwordHash: passwordHash,
                address: address,
                postalCode: postalCode,
                city: city,
                province: province,
                birthDate: hasBirthDate ? birthDate : nil,
                entryYear: entryYear,
                exitYear: exitYear,
                promotion: promotion,
                profession: profession,
                workplace: workplace,
                iban: iban,
                facebookUsername: facebookUsername,
                instagramUsername: instagramUsername,
                xUsername: xUsername,
                tiktokUsername: tiktokUsername,
                photoData: photoData,
                isSearchable: isSearchable,
                associationID: nil,
                isVisibleToOtherAssociations: false,
                membershipStatus: response.member.membershipStatus,
                joinDate: response.member.joinDate,
                syncStatus: .synced,
                serverUpdatedAt: response.member.updatedAt
            )
            
            modelContext.insert(member)
            try modelContext.save()

            dismiss()
            onSuccess()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Validation Row
private struct ValidationRow: View {
    let text: String
    let isValid: Bool
    
    var body: some View {
        HStack {
            Image(systemName: isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(isValid ? .green : .red)
                .imageScale(.small)
            Text(text)
                .font(.caption)
                .foregroundColor(isValid ? .secondary : .red)
        }
    }
}

#Preview {
    SignupView(onSuccess: {})
        .environment(LocalizationManager())
        .environment(\.authService, AuthService())
        .modelContainer(PersistenceController.inMemoryContainer())
}
