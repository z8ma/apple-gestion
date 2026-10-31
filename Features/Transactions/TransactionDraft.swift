import Foundation
import PeculeCore

/// Brouillon d'édition : les changements ne touchent le modèle qu'à l'enregistrement.
struct TransactionDraft {
    /// Valeur saisie, sans signe (le signe découle du type, ADR-006).
    var magnitude: Decimal?
    var kind: TransactionKind = .expense
    /// Sens d'un virement.
    var isOutgoing = true
    var date = Date.now
    var label = ""
    var account: Account?
    var category: Category?
    var nature: String?
    var tags: [Tag] = []
    var note = ""
    var excludedFromBudget = false

    init(account: Account? = nil) {
        self.account = account
    }

    init(_ transaction: Transaction) {
        magnitude = transaction.amount.magnitude
        kind = transaction.kind
        isOutgoing = transaction.amount <= 0
        date = transaction.date
        label = transaction.displayName
        account = transaction.account
        category = transaction.category
        nature = transaction.nature
        tags = transaction.tags ?? []
        note = transaction.note ?? ""
        excludedFromBudget = transaction.excludedFromBudget
    }

    var trimmedLabel: String { label.trimmingCharacters(in: .whitespacesAndNewlines) }

    var signedAmount: Decimal {
        SignedAmount.rounded(SignedAmount.make(magnitude: magnitude ?? 0, kind: kind, outgoing: isOutgoing))
    }

    var isValid: Bool {
        (magnitude ?? 0) > 0 && !trimmedLabel.isEmpty
    }

    /// Catégorie incompatible avec le type choisi (ex. revenu dans « Courses »).
    var categoryMatchesKind: Bool {
        category.map { CategoryKind.allowed(for: kind).contains($0.kind) } ?? true
    }

    func apply(to transaction: Transaction, defaultCurrency: String) {
        if transaction.splits?.isEmpty ?? true {
            transaction.amount = signedAmount
        }
        transaction.kind = kind
        transaction.date = date
        transaction.displayName = trimmedLabel
        if transaction.rawLabel.isEmpty { transaction.rawLabel = trimmedLabel }
        transaction.account = account
        transaction.currency = account?.currency ?? defaultCurrency
        if transaction.category?.id != category?.id {
            transaction.category = category
            transaction.categorizationOrigin = category == nil ? .none : .user
        }
        if category != nil { transaction.needsReview = false }
        transaction.nature = nature
        transaction.tags = tags
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        transaction.note = trimmedNote.isEmpty ? nil : trimmedNote
        transaction.excludedFromBudget = excludedFromBudget
        transaction.touch()
    }
}
