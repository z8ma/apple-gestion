import Foundation
import PeculeCore
import SwiftData
import Testing
@testable import Pecule

@Suite("Persistance et données par défaut")
struct PersistenceTests {
    func makeContext() throws -> ModelContext {
        ModelContext(try PersistenceController.makeContainer(.inMemory))
    }

    @Test("Le premier lancement crée les réglages et les 46 catégories par défaut")
    func seed() throws {
        let context = try makeContext()
        try DefaultDataSeeder.seedIfNeeded(in: context)
        #expect(try context.fetchCount(FetchDescriptor<UserSettings>()) == 1)
        let categories = try context.fetch(FetchDescriptor<Pecule.Category>())
        #expect(categories.count == DefaultCategories.flattened.count)
        #expect(categories.allSatisfy { $0.isSystem })
        let housing = try #require(categories.first { $0.systemKey == "expense.housing" })
        #expect(housing.sortedChildren.map(\.name) == ["Loyer", "Énergie", "Internet & mobile", "Assurance habitation"])
    }

    @Test("Relancer l'initialisation ne crée aucun doublon")
    func idempotent() throws {
        let context = try makeContext()
        try DefaultDataSeeder.seedIfNeeded(in: context)
        try DefaultDataSeeder.seedIfNeeded(in: context)
        #expect(try context.fetchCount(FetchDescriptor<Pecule.Category>()) == DefaultCategories.flattened.count)
        #expect(try context.fetchCount(FetchDescriptor<UserSettings>()) == 1)
    }

    @Test("Une catégorie système renommée n'est pas recréée")
    func renamedSystemCategory() throws {
        let context = try makeContext()
        try DefaultDataSeeder.seedIfNeeded(in: context)
        let rent = try #require(try context.fetch(FetchDescriptor<Pecule.Category>()).first { $0.systemKey == "expense.housing.rent" })
        rent.name = "Mon loyer"
        try DefaultDataSeeder.seedIfNeeded(in: context)
        #expect(try context.fetchCount(FetchDescriptor<Pecule.Category>()) == DefaultCategories.flattened.count)
    }

    @Test("Doublons CloudKit : la catégorie la plus ancienne garde les transactions")
    func mergeDuplicates() throws {
        let context = try makeContext()
        try DefaultDataSeeder.seedIfNeeded(in: context)
        let original = try #require(try context.fetch(FetchDescriptor<Pecule.Category>()).first { $0.systemKey == "expense.food.groceries" })
        let duplicate = Pecule.Category(name: "Courses", symbol: "basket.fill", colorHex: "#3FA34D", kind: .expense)
        duplicate.isSystem = true
        duplicate.systemKey = "expense.food.groceries"
        duplicate.createdAt = original.createdAt.addingTimeInterval(60)
        context.insert(duplicate)
        let transaction = Transaction(amount: -12, label: "Marché", kind: .expense)
        transaction.category = duplicate
        context.insert(transaction)
        try context.save()

        try DefaultDataSeeder.seedIfNeeded(in: context)

        let groceries = try context.fetch(FetchDescriptor<Pecule.Category>()).filter { $0.systemKey == "expense.food.groceries" }
        #expect(groceries.count == 1)
        #expect(transaction.category?.id == original.id)
    }

    @Test("Réglages en double : un seul subsiste, le plus ancien")
    func settingsSingleton() throws {
        let context = try makeContext()
        let first = try SettingsStore.current(in: context)
        let second = UserSettings()
        second.createdAt = first.createdAt.addingTimeInterval(10)
        context.insert(second)
        try context.save()
        #expect(try SettingsStore.current(in: context) === first)
        try context.save()
        #expect(try context.fetchCount(FetchDescriptor<UserSettings>()) == 1)
    }

    @Test("Valeurs par défaut des réglages conformes à la spec")
    func settingsDefaults() throws {
        let settings = try SettingsStore.current(in: try makeContext())
        #expect(settings.periodStartDay == 1)
        #expect(settings.defaultCurrency == "EUR")
        #expect(settings.alertThresholds == SettingsDefaults.alertThresholds)
        #expect(settings.budgetMode == .categoryMonthly)
    }

    @Test("Supprimer un parent de split supprime ses parts")
    func splitCascade() throws {
        let context = try makeContext()
        let parent = Transaction(amount: -30, label: "Courses", kind: .expense)
        context.insert(parent)
        let part = Transaction(amount: -30, label: "Courses", kind: .expense)
        part.parent = parent
        context.insert(part)
        try context.save()
        context.delete(parent)
        try context.save()
        #expect(try context.fetchCount(FetchDescriptor<Transaction>()) == 0)
    }
}
