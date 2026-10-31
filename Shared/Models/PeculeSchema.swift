import SwiftData

/// Liste des entités persistées (M1–M5). Goal et NetWorthSnapshot arriveront en M6.
enum PeculeSchema {
    static let models: [any PersistentModel.Type] = [
        UserSettings.self,
        Account.self,
        BankConnection.self,
        Transaction.self,
        Category.self,
        Tag.self,
        Rule.self,
        BudgetTarget.self,
        Envelope.self,
        EnvelopeAllocation.self,
        Subscription.self,
    ]

    static var schema: Schema { Schema(models) }
}
