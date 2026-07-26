import SwiftUI
import SwiftData

/// Pantalla de login con email y contraseña
/// Aparece después del splash si no hay token válido
struct LoginView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.authService) private var authService
    @Environment(LocalizationManager.self) private var loc
    
    let onLoginSuccess: () -> Void
    
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSignup = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // Logo o título
                VStack(spacing: 8) {
                    Image(systemName: "person.2.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.blue.gradient)
                    
                    Text("Asocia")
                        .font(.largeTitle.bold())
                }
                .padding(.top, 60)
                
                // Formulario de login
                VStack(spacing: 16) {
                    // Email
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .textFieldStyle(.roundedBorder)
                        .disabled(isLoading)
                        .padding(.horizontal, 32)
                    
                    // Password
                    SecureField("Contraseña", text: $password)
                        .textContentType(.password)
                        .textFieldStyle(.roundedBorder)
                        .disabled(isLoading)
                        .padding(.horizontal, 32)
                    
                    // Botón de login
                    Button {
                        Task { await login() }
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.white)
                            } else {
                                Text("Iniciar Sesión")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canLogin ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(!canLogin || isLoading)
                    .padding(.horizontal, 32)
                }
                
                // Mensaje de error
                if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                Spacer()
                
                // Botón para ir a registro
                VStack(spacing: 12) {
                    Text("¿No tienes cuenta?")
                        .foregroundColor(.secondary)
                    
                    Button {
                        showSignup = true
                    } label: {
                        Text("Crear Cuenta")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                    .disabled(isLoading)
                }
                .padding(.bottom, 40)
            }
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $showSignup) {
                SignupView(onSuccess: {
                    showSignup = false
                    onLoginSuccess()
                })
            }
        }
    }
    
    private var canLogin: Bool {
        !email.isEmpty && !password.isEmpty
    }
    
    private func login() async {
        errorMessage = nil
        isLoading = true
        
        do {
            let response = try await authService.login(email: email, password: password)
            
            // Guardar miembro en SwiftData
            let member = response.member.toMember()
            modelContext.insert(member)
            try? modelContext.save()
            
            // Notificar éxito
            await MainActor.run {
                onLoginSuccess()
            }
            
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}

// MARK: - Conversión Member <-> MemberDTO

extension MemberDTO {
    func toMember() -> Member {
        Member(
            id: id,
            firstName: firstName,
            firstSurname: firstSurname,
            secondSurname: secondSurname,
            email: email,
            secondaryEmail: secondaryEmail,
            mobilePhone: mobilePhone,
            landlinePhone: landlinePhone,
            passwordHash: "", // No guardamos el hash en local después del login
            address: address,
            postalCode: postalCode,
            city: city,
            province: province,
            birthDate: birthDate,
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
            photoData: photoBase64 != nil ? Data(base64Encoded: photoBase64!) : nil,
            isSearchable: isSearchable,
            associationID: associationID,
            isVisibleToOtherAssociations: isVisibleToOtherAssociations,
            membershipStatus: membershipStatus,
            joinDate: joinDate,
            rejectionReason: rejectionReason,
            syncStatus: .synced,
            serverUpdatedAt: updatedAt
        )
    }
}

extension Member {
    func toDTO() -> MemberDTO {
        MemberDTO(
            id: id,
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
            birthDate: birthDate,
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
            associationID: associationID,
            isVisibleToOtherAssociations: isVisibleToOtherAssociations,
            membershipStatus: membershipStatus,
            joinDate: joinDate,
            rejectionReason: rejectionReason,
            updatedAt: serverUpdatedAt ?? localUpdatedAt
        )
    }
}

#Preview {
    LoginView(onLoginSuccess: {})
        .environment(LocalizationManager())
        .environment(\.authService, AuthService())
        .modelContainer(PersistenceController.inMemoryContainer())
}
