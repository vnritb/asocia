import SwiftUI
import SwiftData

/// Formulario de alta de nuevo socio (sin pago).
///
/// Orden de operaciones (ver docs/ARQUITECTURA.md):
/// 1. Validar el formulario: nombre + primer apellido, y al menos un
///    contacto (email, móvil o fijo). El resto de campos son opcionales.
/// 2. Enviar la solicitud al backend (`apiClient.submitMembershipApplication`),
///    que crea el registro en estado `pendingApproval` y devuelve un token de sesión.
/// 3. Guardar el `Member` resultante en SwiftData (local, offline-first) y
///    cerrar el formulario; `RootView` pasa automáticamente a mostrar la
///    ficha del socio con el aviso de "pendiente de confirmar".
/// 4. Más adelante, el equipo gestor confirma o rechaza el alta desde el
///    backoffice; al confirmarla, el indicador provisional desaparece y se
///    habilita el acceso al Chat.
struct SignupView: View {
    @Environment(\.apiClient) private var apiClient
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(LocalizationManager.self) private var loc

    @State private var photoData: Data?

    @State private var firstName = ""
    @State private var firstSurname = ""
    @State private var secondSurname = ""

    @State private var email = ""
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
        Member.isValidApplication(
            firstName: firstName, firstSurname: firstSurname,
            email: email, mobilePhone: mobilePhone, landlinePhone: landlinePhone
        )
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

                Section(loc.t("signup.section.personalData")) {
                    TextField(loc.t("signup.field.firstName"), text: $firstName)
                        .textContentType(.givenName)
                    TextField(loc.t("signup.field.firstSurname"), text: $firstSurname)
                        .textContentType(.familyName)
                    TextField(loc.t("signup.field.secondSurname"), text: $secondSurname)
                        .textContentType(.familyName)
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

                Section(loc.t("signup.section.contact")) {
                    TextField(loc.t("signup.field.email"), text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    TextField(loc.t("signup.field.email2"), text: $secondaryEmail)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    TextField(loc.t("signup.field.mobilePhone"), text: $mobilePhone)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                    TextField(loc.t("signup.field.landlinePhone"), text: $landlinePhone)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
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
                }
            }
            .navigationTitle(loc.t("signup.navTitle"))
            .navigationBarTitleDisplayMode(.inline)
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
            let dto = MemberDTO(
                id: localID,
                firstName: firstName,
                firstSurname: firstSurname,
                secondSurname: secondSurname,
                email: email,
                secondaryEmail: secondaryEmail,
                mobilePhone: mobilePhone,
                landlinePhone: landlinePhone,
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
                photoBase64: photoData?.base64EncodedString(),
                isSearchable: isSearchable,
                associationID: nil,
                isVisibleToOtherAssociations: false,
                membershipStatus: .pendingApproval,
                joinDate: nil,
                rejectionReason: nil,
                updatedAt: .now
            )

            let response = try await apiClient.submitMembershipApplication(dto)

            let member = Member(
                id: response.member.id,
                firstName: response.member.firstName,
                firstSurname: response.member.firstSurname,
                secondSurname: response.member.secondSurname,
                email: response.member.email,
                secondaryEmail: response.member.secondaryEmail,
                mobilePhone: response.member.mobilePhone,
                landlinePhone: response.member.landlinePhone,
                address: response.member.address,
                postalCode: response.member.postalCode,
                city: response.member.city,
                province: response.member.province,
                birthDate: response.member.birthDate,
                entryYear: response.member.entryYear,
                exitYear: response.member.exitYear,
                promotion: response.member.promotion,
                profession: response.member.profession,
                workplace: response.member.workplace,
                iban: response.member.iban,
                facebookUsername: response.member.facebookUsername,
                instagramUsername: response.member.instagramUsername,
                xUsername: response.member.xUsername,
                tiktokUsername: response.member.tiktokUsername,
                photoData: photoData,
                isSearchable: response.member.isSearchable,
                associationID: response.member.associationID,
                isVisibleToOtherAssociations: response.member.isVisibleToOtherAssociations,
                membershipStatus: response.member.membershipStatus,
                joinDate: response.member.joinDate,
                syncStatus: .synced,
                serverUpdatedAt: response.member.updatedAt
            )
            modelContext.insert(member)
            try modelContext.save()

            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    SignupView()
        .environment(LocalizationManager(translationClient: TranslationAPIClient()))
        .modelContainer(PersistenceController.inMemoryContainer())
}
