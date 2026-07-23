import SwiftUI

/// Pantalla para quien todavía NO es socio: un único botón que ocupa toda
/// la pantalla con el texto "Asocia". Al pulsarlo se abre el formulario de
/// alta (`SignupView`), sin ningún pago. "Asocia" es el nombre de la app y
/// no se traduce; el resto de textos de la app sí.
struct MembershipButtonView: View {
    @Environment(LocalizationManager.self) private var loc

    @State private var showSignup = false
    @State private var showSettings = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button {
                showSignup = true
            } label: {
                ZStack {
                    Color.accentColor.ignoresSafeArea()
                    Text("Asocia")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
            .buttonStyle(.plain)
            .accessibilityHint(loc.t("membershipButton.accessibilityHint"))

            // Botón de ajustes (idioma) accesible incluso antes de ser socio.
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .padding()
            }
            .padding(.top, 44)
        }
        .fullScreenCover(isPresented: $showSignup) {
            SignupView()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
}

#Preview {
    MembershipButtonView()
        .environment(LocalizationManager(translationClient: TranslationAPIClient()))
}
