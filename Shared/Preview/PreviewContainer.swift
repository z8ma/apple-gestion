import Foundation
import SwiftData

/// Conteneur en mémoire pour les previews SwiftUI et les tests.
enum PreviewContainer {
    /// Store vide avec réglages et catégories par défaut.
    static func make() -> ModelContainer {
        do {
            let container = try PersistenceController.makeContainer(.inMemory)
            try DefaultDataSeeder.seedIfNeeded(in: container.mainContext)
            return container
        } catch {
            preconditionFailure("Conteneur de preview impossible : \(error)")
        }
    }
}
