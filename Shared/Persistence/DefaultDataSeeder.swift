import Foundation
import PeculeCore
import SwiftData

/// Données créées au premier lancement : réglages et catégories par défaut (E.6).
/// Idempotent : peut être appelé à chaque lancement et après chaque synchro.
enum DefaultDataSeeder {
    static func seedIfNeeded(in context: ModelContext) throws {
        try SettingsStore.current(in: context)
        try deduplicateSystemCategories(in: context)
        try seedCategories(in: context)
        try context.save()
    }

    /// Crée les catégories système manquantes (identifiées par `systemKey`).
    static func seedCategories(in context: ModelContext) throws {
        let existing = try context.fetch(FetchDescriptor<Category>(predicate: #Predicate { $0.systemKey != nil }))
        var byKey: [String: Category] = [:]
        for category in existing {
            if let key = category.systemKey { byKey[key] = category }
        }
        for (index, seed) in DefaultCategories.all.enumerated() {
            let parent = byKey[seed.key] ?? insert(seed, parent: nil, sortOrder: index, in: context)
            byKey[seed.key] = parent
            for (childIndex, childSeed) in seed.children.enumerated() where byKey[childSeed.key] == nil {
                byKey[childSeed.key] = insert(childSeed, parent: parent, sortOrder: childIndex, in: context)
            }
        }
    }

    /// Fusionne les catégories système en double (créées sur deux appareils avant la synchro).
    static func deduplicateSystemCategories(in context: ModelContext) throws {
        let all = try context.fetch(FetchDescriptor<Category>(predicate: #Predicate { $0.systemKey != nil }))
        let groups = Deduplication.groups(all, key: { $0.systemKey }, createdAt: { $0.createdAt }, id: { $0.id })
        for group in groups {
            for duplicate in group.duplicates {
                merge(duplicate, into: group.keeper)
                context.delete(duplicate)
            }
        }
    }

    private static func merge(_ duplicate: Category, into keeper: Category) {
        for transaction in duplicate.transactions ?? [] { transaction.category = keeper }
        for child in duplicate.children ?? [] { child.parent = keeper }
        for target in duplicate.budgetTargets ?? [] { target.category = keeper }
        for subscription in duplicate.subscriptions ?? [] { subscription.category = keeper }
        for rule in duplicate.rulesSettingCategory ?? [] { rule.setCategory = keeper }
        for envelope in duplicate.envelopes ?? [] {
            var categories = envelope.categories ?? []
            categories.removeAll { $0 === duplicate }
            if !categories.contains(where: { $0 === keeper }) { categories.append(keeper) }
            envelope.categories = categories
        }
        keeper.updatedAt = .now
    }

    private static func insert(_ seed: CategorySeed, parent: Category?, sortOrder: Int, in context: ModelContext) -> Category {
        let category = Category(name: seed.name, symbol: seed.symbol, colorHex: seed.colorHex, kind: seed.kind, parent: parent, sortOrder: sortOrder)
        category.isSystem = true
        category.systemKey = seed.key
        context.insert(category)
        return category
    }
}
