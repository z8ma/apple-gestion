import SwiftData
import SwiftUI

@main
struct PeculeApp: App {
    let container: ModelContainer

    init() {
        container = PersistenceController.makeAppContainer()
        try? DefaultDataSeeder.seedIfNeeded(in: container.mainContext)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
