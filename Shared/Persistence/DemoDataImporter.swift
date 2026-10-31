import Foundation
import PeculeCore
import SwiftData

/// Import des données de démo (PeculeCore) dans SwiftData, et remise à zéro.
enum DemoDataImporter {
    struct Summary: Equatable {
        let accounts: Int
        let transactions: Int
    }

    @discardableResult
    static func importDemo(months: Int = 6, into context: ModelContext, now: Date = .now, calendar: Calendar = .current) throws -> Summary {
        try DefaultDataSeeder.seedIfNeeded(in: context)
        let dataset = DemoDataGenerator.make(months: months, endingAt: now, calendar: calendar)

        let categories = try context.fetch(FetchDescriptor<Category>(predicate: #Predicate { $0.systemKey != nil }))
        let categoryByKey = Dictionary(categories.compactMap { c in c.systemKey.map { ($0, c) } }, uniquingKeysWith: { first, _ in first })

        var accountByKey: [String: Account] = [:]
        let existingCount = try context.fetchCount(FetchDescriptor<Account>())
        for (index, demo) in dataset.accounts.enumerated() {
            let account = Account(name: demo.name, type: demo.type)
            account.institutionName = demo.institution
            account.colorHex = demo.colorHex
            account.includeInBudget = demo.includeInBudget
            account.budgetSharePercent = demo.budgetSharePercent
            account.balance = dataset.closingBalance(of: demo.key)
            account.balanceDate = now
            account.sortOrder = existingCount + index
            context.insert(account)
            accountByKey[demo.key] = account
        }

        var tagByName: [String: Tag] = [:]
        for (name, color) in dataset.tags {
            let tag = Tag(name: name, colorHex: color)
            context.insert(tag)
            tagByName[name] = tag
        }

        var transactionByID: [Int: Transaction] = [:]
        for demo in dataset.transactions {
            let transaction = Transaction(amount: demo.amount, date: demo.date, label: demo.label, kind: demo.kind,
                                          source: .import, account: accountByKey[demo.accountKey])
            transaction.bookingDate = demo.date
            transaction.category = demo.categoryKey.flatMap { categoryByKey[$0] }
            transaction.categorizationOrigin = transaction.category == nil ? .none : .user
            transaction.needsReview = transaction.category == nil
            transaction.nature = demo.nature
            transaction.tags = demo.tags.compactMap { tagByName[$0] }
            transaction.excludedFromBudget = demo.kind == .transfer
            transaction.linkedRefundOf = demo.refundOf.flatMap { transactionByID[$0] }
            context.insert(transaction)
            transactionByID[demo.id] = transaction
        }
        try context.save()
        return Summary(accounts: dataset.accounts.count, transactions: dataset.transactions.count)
    }

    /// Supprime toutes les données (transactions, comptes, tags, règles, budgets…),
    /// puis recrée les catégories et réglages par défaut.
    static func eraseAll(in context: ModelContext) throws {
        // Suppression objet par objet : applique les règles de suppression des relations,
        // contrairement à la suppression en masse.
        try deleteAll(Transaction.self, in: context)
        try deleteAll(Account.self, in: context)
        try deleteAll(BankConnection.self, in: context)
        try deleteAll(Tag.self, in: context)
        try deleteAll(Rule.self, in: context)
        try deleteAll(BudgetTarget.self, in: context)
        try deleteAll(EnvelopeAllocation.self, in: context)
        try deleteAll(Envelope.self, in: context)
        try deleteAll(Subscription.self, in: context)
        try deleteAll(Category.self, in: context)
        try deleteAll(UserSettings.self, in: context)
        try context.save()
        try DefaultDataSeeder.seedIfNeeded(in: context)
    }

    private static func deleteAll<Model: PersistentModel>(_ type: Model.Type, in context: ModelContext) throws {
        for object in try context.fetch(FetchDescriptor<Model>()) {
            context.delete(object)
        }
    }
}
