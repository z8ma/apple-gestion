import Foundation
import OSLog
import SwiftData

/// Création du `ModelContainer` : store dans l'App Group, synchronisé via CloudKit
/// (base privée), avec replis propres si iCloud n'est pas disponible.
enum PersistenceController {
    enum StoreKind: Equatable {
        /// App Group + CloudKit (cas nominal).
        case cloudKit
        /// App Group, sans synchronisation (iCloud indisponible).
        case local
        /// Tests et previews.
        case inMemory
    }

    private static let logger = Logger(subsystem: "Pecule", category: "Persistence")

    static var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    static func makeContainer(_ kind: StoreKind) throws -> ModelContainer {
        let schema = PeculeSchema.schema
        let configuration: ModelConfiguration
        switch kind {
        case .inMemory:
            configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        case .local:
            configuration = ModelConfiguration(schema: schema, groupContainer: groupContainer, cloudKitDatabase: .none)
        case .cloudKit:
            guard let containerID = AppConfiguration.cloudKitContainerIdentifier else {
                throw PersistenceError.missingCloudKitContainer
            }
            configuration = ModelConfiguration(schema: schema, groupContainer: groupContainer, cloudKitDatabase: .private(containerID))
        }
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    /// Conteneur de l'app : CloudKit, sinon local, sinon mémoire (jamais de crash au lancement).
    static func makeAppContainer() -> ModelContainer {
        let order: [StoreKind] = isRunningTests ? [.inMemory] : [.cloudKit, .local, .inMemory]
        for kind in order {
            do {
                let container = try makeContainer(kind)
                logger.info("Store ouvert : \(String(describing: kind), privacy: .public)")
                return container
            } catch {
                logger.error("Échec du store \(String(describing: kind), privacy: .public) : \(error.localizedDescription, privacy: .public)")
            }
        }
        preconditionFailure("Impossible de créer un store, même en mémoire")
    }

    private static var groupContainer: ModelConfiguration.GroupContainer {
        AppConfiguration.appGroupIdentifier.map { .identifier($0) } ?? .none
    }
}

enum PersistenceError: Error {
    case missingCloudKitContainer
}
