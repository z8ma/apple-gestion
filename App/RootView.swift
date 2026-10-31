import SwiftUI

/// Racine de l'app : onglets principaux.
struct RootView: View {
    var body: some View {
        TabView {
            Tab("Accueil", systemImage: "house") {
                HomeView()
            }
            Tab("Transactions", systemImage: "list.bullet.rectangle") {
                TransactionsListView()
            }
            Tab("Comptes", systemImage: "building.columns") {
                AccountsListView()
            }
            Tab("Réglages", systemImage: "gearshape") {
                SettingsView()
            }
        }
    }
}

#Preview {
    RootView()
        .modelContainer(PreviewData.container())
}
