import Foundation
import SwiftData

/// Accès au singleton `UserSettings`. Après une synchro CloudKit, deux appareils peuvent
/// en avoir créé un chacun : on garde le plus ancien et on supprime les autres.
enum SettingsStore {
    @discardableResult
    static func current(in context: ModelContext) throws -> UserSettings {
        let descriptor = FetchDescriptor<UserSettings>(sortBy: [SortDescriptor(\.createdAt)])
        let all = try context.fetch(descriptor)
        guard let first = all.first else {
            let settings = UserSettings()
            context.insert(settings)
            return settings
        }
        for duplicate in all.dropFirst() {
            context.delete(duplicate)
        }
        return first
    }
}
