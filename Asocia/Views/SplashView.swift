import SwiftUI
import UIKit

/// Splash de presentación: título "Asocia" + logo, ~1.2s al arrancar.
///
/// El logo es un `Image("AsociaLogo")` si añades ese asset a
/// `Assets.xcassets`; mientras tanto cae en un símbolo SF Symbol para que
/// el proyecto compile y se vea razonable desde el primer momento.
struct SplashView: View {
    var body: some View {
        ZStack {
            Color.accentColor.ignoresSafeArea()

            VStack(spacing: 20) {
                logo
                    .resizable()
                    .scaledToFit()
                    .frame(width: 96, height: 96)
                    .foregroundStyle(.white)

                Text("Asocia")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
    }

    private var logo: Image {
        if UIImage(named: "AsociaLogo") != nil {
            Image("AsociaLogo")
        } else {
            Image(systemName: "person.3.fill")
        }
    }
}

#Preview {
    SplashView()
}
