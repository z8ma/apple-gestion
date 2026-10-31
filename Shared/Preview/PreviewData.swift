import Foundation
import PeculeCore
import SwiftData

/// Jeu de données fictif minimal pour les previews (le générateur complet est le menu debug).
enum PreviewData {
    static func container() -> ModelContainer {
        let container = PreviewContainer.make()
        populate(container.mainContext)
        return container
    }

    static func category(_ key: String, in context: ModelContext) -> Category? {
        try? context.fetch(FetchDescriptor<Category>(predicate: #Predicate { $0.systemKey == key })).first
    }

    @discardableResult
    static func populate(_ context: ModelContext) -> [Transaction] {
        let checking = Account(name: "Compte courant", type: .checking)
        checking.institutionName = "Ma Banque"
        checking.balance = .exact("1842.17")
        let savings = Account(name: "Livret A", type: .savings)
        savings.balance = 6_500
        savings.includeInBudget = false
        savings.colorHex = "#16A085"
        savings.sortOrder = 1
        context.insert(checking)
        context.insert(savings)

        let trip = Tag(name: "Vacances Italie", colorHex: "#F2994A")
        context.insert(trip)

        let calendar = Calendar.current
        func daysAgo(_ n: Int, hour: Int = 12) -> Date {
            calendar.date(byAdding: .day, value: -n, to: calendar.date(bySettingHour: hour, minute: 0, second: 0, of: .now) ?? .now) ?? .now
        }
        let rows: [(Decimal, String, String?, TransactionKind, Int)] = [
            (.exact("-23.40"), "Carrefour City", "expense.food.groceries", .expense, 0),
            (.exact("-4.20"), "Café de la Gare", "expense.food.cafes", .expense, 0),
            (.exact("-58.00"), "Total Énergies", "expense.transport.fuel", .expense, 1),
            (.exact("2450.00"), "Salaire", "income.salary", .income, 2),
            (.exact("-890.00"), "Loyer", "expense.housing.rent", .expense, 3),
            (.exact("-15.99"), "Netflix", "expense.subscriptions.streaming", .expense, 4),
            (.exact("-42.00"), "Trattoria Roma", "expense.food.restaurants", .expense, 6),
            (.exact("12.00"), "Remboursement Lydia", "expense.food.restaurants", .refund, 6),
            (.exact("-37.50"), "Achat inconnu", nil, .expense, 8),
        ]
        var created: [Transaction] = []
        for (amount, label, key, kind, ago) in rows {
            let transaction = Transaction(amount: amount, date: daysAgo(ago), label: label, kind: kind, account: checking)
            if let key {
                transaction.category = category(key, in: context)
                transaction.categorizationOrigin = .user
            } else {
                transaction.needsReview = true
            }
            if label == "Trattoria Roma" { transaction.tags = [trip] }
            context.insert(transaction)
            created.append(transaction)
        }
        try? context.save()
        return created
    }
}
