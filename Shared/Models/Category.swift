import Foundation
import PeculeCore
import SwiftData

@Model
final class Category {
    var id: UUID = UUID()
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now

    var name: String = ""
    /// SF Symbol.
    var symbol: String = "tag.fill"
    var colorHex: String = "#BDBDBD"

    /// Un seul niveau de sous-catégorie.
    var parent: Category?
    @Relationship(deleteRule: .cascade, inverse: \Category.parent)
    var children: [Category]? = []

    var kindRaw: String = CategoryKind.expense.rawValue
    var sortOrder: Int = 0
    var isArchived: Bool = false
    /// Catégorie système : non supprimable, mais renommable.
    var isSystem: Bool = false
    /// Clé stable des catégories par défaut (E.6), pour dédoublonner après synchro CloudKit (ADR-010).
    var systemKey: String?

    @Relationship(deleteRule: .nullify, inverse: \Transaction.category)
    var transactions: [Transaction]? = []
    @Relationship(deleteRule: .cascade, inverse: \BudgetTarget.category)
    var budgetTargets: [BudgetTarget]? = []
    @Relationship(deleteRule: .nullify, inverse: \Subscription.category)
    var subscriptions: [Subscription]? = []
    @Relationship(deleteRule: .nullify, inverse: \Rule.setCategory)
    var rulesSettingCategory: [Rule]? = []
    /// Inverse de `Envelope.categories`.
    var envelopes: [Envelope]? = []

    init(name: String, symbol: String, colorHex: String, kind: CategoryKind, parent: Category? = nil, sortOrder: Int = 0) {
        self.name = name
        self.symbol = symbol
        self.colorHex = colorHex
        self.kindRaw = kind.rawValue
        self.parent = parent
        self.sortOrder = sortOrder
    }

    var kind: CategoryKind {
        get { .decoded(kindRaw, default: .expense) }
        set { kindRaw = newValue.rawValue }
    }

    var sortedChildren: [Category] {
        (children ?? []).sorted { ($0.sortOrder, $0.name) < ($1.sortOrder, $1.name) }
    }

    /// Nom complet « Parent › Enfant ».
    var fullName: String {
        parent.map { "\($0.name) › \(name)" } ?? name
    }
}
