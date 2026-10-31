import Foundation
import PeculeCore
import SwiftData

/// Règle de catégorisation (M2). Toutes les conditions renseignées doivent être vraies.
@Model
final class Rule {
    var id: UUID = UUID()
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now

    var name: String = ""
    var priority: Int = 0
    var isEnabled: Bool = true

    // Conditions
    var labelMatchKindRaw: String?
    var labelPattern: String?
    var amountMin: Decimal?
    var amountMax: Decimal?
    @Relationship(deleteRule: .nullify, inverse: \Account.rules)
    var accounts: [Account]? = []
    var sourcesRaw: [String]?

    // Actions
    var setCategory: Category?
    var rename: String?
    var addTags: [Tag]? = []
    var setNature: String?
    var setKindRaw: String?
    var excludeFromBudget: Bool?

    var createdFromCorrection: Bool = false
    var matchCount: Int = 0

    init(name: String, priority: Int = 0) {
        self.name = name
        self.priority = priority
    }

    var labelMatchKind: LabelMatchKind? {
        get { labelMatchKindRaw.flatMap(LabelMatchKind.init(rawValue:)) }
        set { labelMatchKindRaw = newValue?.rawValue }
    }

    var sources: [TransactionSource]? {
        get { sourcesRaw?.compactMap(TransactionSource.init(rawValue:)) }
        set { sourcesRaw = newValue?.map(\.rawValue) }
    }

    var setKind: TransactionKind? {
        get { setKindRaw.flatMap(TransactionKind.init(rawValue:)) }
        set { setKindRaw = newValue?.rawValue }
    }
}
