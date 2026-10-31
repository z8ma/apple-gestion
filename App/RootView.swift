import SwiftUI

/// Racine de l'app : onglets principaux (complétée par les features M1).
struct RootView: View {
    var body: some View {
        TabView {
            Tab("Accueil", systemImage: "house") {
                HomeView()
            }
        }
    }
}

#Preview {
    RootView()
}
