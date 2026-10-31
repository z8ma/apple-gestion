import SwiftData
import SwiftUI

@main
struct PeculeApp: App {
    let container: ModelContainer
    @State private var lock: AppLockController

    init() {
        let container = PersistenceController.makeAppContainer()
        try? DefaultDataSeeder.seedIfNeeded(in: container.mainContext)
        let lockEnabled = (try? SettingsStore.current(in: container.mainContext).lockWithBiometrics) ?? false
        self.container = container
        _lock = State(initialValue: AppLockController(isEnabled: lockEnabled))
    }

    var body: some Scene {
        WindowGroup {
            LockContainerView {
                RootView()
            }
            .environment(lock)
        }
        .modelContainer(container)
    }
}
