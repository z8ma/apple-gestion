import Foundation
import PeculeCore
import SwiftData
import Testing
@testable import Pecule

@Suite("Import des données de démo")
struct DemoDataImporterTests {
    @Test("Import : comptes, transactions, catégories et remboursements liés")
    func importDemo() throws {
        let context = ModelContext(try PersistenceController.makeContainer(.inMemory))
        let summary = try DemoDataImporter.importDemo(into: context)
        #expect(try context.fetchCount(FetchDescriptor<Account>()) == 3)
        let transactions = try context.fetch(FetchDescriptor<Transaction>())
        #expect(transactions.count == summary.transactions)
        #expect(transactions.filter { $0.category == nil }.allSatisfy { $0.needsReview })
        #expect(transactions.contains { $0.linkedRefundOf != nil })
        #expect(transactions.filter { $0.kind == .transfer }.allSatisfy { $0.excludedFromBudget })
    }

    @Test("Tout effacer : il ne reste que les réglages et catégories par défaut")
    func eraseAll() throws {
        let context = ModelContext(try PersistenceController.makeContainer(.inMemory))
        try DemoDataImporter.importDemo(into: context)
        try DemoDataImporter.eraseAll(in: context)
        #expect(try context.fetchCount(FetchDescriptor<Transaction>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<Account>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<Pecule.Category>()) == DefaultCategories.flattened.count)
        #expect(try context.fetchCount(FetchDescriptor<UserSettings>()) == 1)
    }
}
