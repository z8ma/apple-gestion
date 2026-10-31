import Testing
@testable import Pecule

@Suite("Configuration de l'app")
struct AppConfigurationTests {
    @Test("L'App Group est renseigné depuis le xcconfig")
    func appGroup() {
        let group = AppConfiguration.appGroupIdentifier
        #expect(group?.hasPrefix("group.") == true)
        #expect(group?.hasSuffix(".pecule") == true)
    }

    @Test("Le conteneur CloudKit est renseigné depuis le xcconfig")
    func cloudKitContainer() {
        #expect(AppConfiguration.cloudKitContainerIdentifier?.hasPrefix("iCloud.") == true)
    }
}
