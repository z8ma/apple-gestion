import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Bienvenue dans Pécule",
                systemImage: "eurosign.circle",
                description: Text("Ajoutez un compte pour commencer.")
            )
            .navigationTitle("Accueil")
        }
    }
}

#Preview {
    HomeView()
}
