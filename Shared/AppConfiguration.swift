import Foundation

/// Identifiants lus dans l'Info.plist (renseignés par Config/Pecule.xcconfig).
/// Partagé entre l'app et les extensions.
nonisolated enum AppConfiguration {
    /// App Group contenant le store SwiftData partagé avec les widgets et les intents.
    static var appGroupIdentifier: String? { value(for: "PeculeAppGroup") }

    /// Conteneur CloudKit (base privée de l'utilisateur).
    static var cloudKitContainerIdentifier: String? { value(for: "PeculeCloudKitContainer") }

    private static func value(for key: String) -> String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String,
              !value.isEmpty,
              !value.contains("$(")
        else { return nil }
        return value
    }
}
