import Foundation
import PeculeCore
import SwiftData

@Model
final class Account {
    var id: UUID = UUID()
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now

    var name: String = ""
    var institutionName: String?
    var typeRaw: String = AccountType.checking.rawValue
    var balance: Decimal = 0
    var balanceDate: Date = Date.now
    var currency: String = SettingsDefaults.currency

    var isManual: Bool = true
    var connection: BankConnection?
    var providerAccountID: String?

    var includeInBudget: Bool = true
    /// Part personnelle en % (ex. 50 pour un compte joint).
    var budgetSharePercent: Decimal = SettingsDefaults.budgetSharePercent
    var includeInNetWorth: Bool = true
    var colorHex: String = "#5E7CE2"
    var sortOrder: Int = 0
    var isArchived: Bool = false

    @Relationship(deleteRule: .cascade, inverse: \Transaction.account)
    var transactions: [Transaction]? = []

    /// Règles dont la condition porte sur ce compte (inverse de `Rule.accounts`).
    var rules: [Rule]? = []

    init(name: String, type: AccountType = .checking, currency: String = SettingsDefaults.currency) {
        self.name = name
        self.typeRaw = type.rawValue
        self.currency = currency
    }

    var type: AccountType {
        get { .decoded(typeRaw, default: .checking) }
        set { typeRaw = newValue.rawValue }
    }
}
