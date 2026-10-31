import Foundation
import PeculeCore
import SwiftData

/// Opération (dépense, revenu, virement, remboursement).
///
/// Convention de signe : sortie d'argent < 0, entrée > 0 (ADR-006).
/// Split : la somme des enfants (`splits`) vaut le montant du parent ; le parent est
/// exclu des calculs, les enfants comptent.
///
/// Nom : `Transaction` comme dans la spec (ADR-009). Qualifier `SwiftUI.Transaction`
/// ou `StoreKit.Transaction` là où il y a ambiguïté.
@Model
final class Transaction {
    var id: UUID = UUID()
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now

    var amount: Decimal = 0
    var currency: String = SettingsDefaults.currency
    /// Date d'opération.
    var date: Date = Date.now
    /// Date de comptabilisation côté banque.
    var bookingDate: Date?

    var rawLabel: String = ""
    var displayName: String = ""
    /// Commerçant normalisé (annexe E.2).
    var merchantKey: String = ""

    var category: Category?
    var nature: String?
    var tags: [Tag]? = []
    var note: String?

    var kindRaw: String = TransactionKind.expense.rawValue
    var sourceRaw: String = TransactionSource.manual.rawValue
    var statusRaw: String = TransactionStatus.posted.rawValue

    var account: Account?
    var providerTransactionID: String?
    var cardName: String?

    var excludedFromBudget: Bool = false
    var needsReview: Bool = false
    var categorizationOriginRaw: String = CategorizationOrigin.none.rawValue

    var parent: Transaction?
    @Relationship(deleteRule: .cascade, inverse: \Transaction.parent)
    var splits: [Transaction]? = []

    /// Transaction d'origine que celle-ci rembourse.
    var linkedRefundOf: Transaction?
    @Relationship(deleteRule: .nullify, inverse: \Transaction.linkedRefundOf)
    var refunds: [Transaction]? = []

    @Attribute(.externalStorage)
    var receiptImage: Data?

    init(
        amount: Decimal,
        date: Date = .now,
        label: String,
        kind: TransactionKind,
        source: TransactionSource = .manual,
        currency: String = SettingsDefaults.currency,
        account: Account? = nil
    ) {
        self.amount = amount
        self.date = date
        self.rawLabel = label
        self.displayName = label
        self.kindRaw = kind.rawValue
        self.sourceRaw = source.rawValue
        self.currency = currency
        self.account = account
    }

    var kind: TransactionKind {
        get { .decoded(kindRaw, default: .expense) }
        set { kindRaw = newValue.rawValue }
    }

    var source: TransactionSource {
        get { .decoded(sourceRaw, default: .manual) }
        set { sourceRaw = newValue.rawValue }
    }

    var status: TransactionStatus {
        get { .decoded(statusRaw, default: .posted) }
        set { statusRaw = newValue.rawValue }
    }

    var categorizationOrigin: CategorizationOrigin {
        get { .decoded(categorizationOriginRaw, default: .none) }
        set { categorizationOriginRaw = newValue.rawValue }
    }

    var isSplitParent: Bool { !(splits ?? []).isEmpty }
    var isSplitPart: Bool { parent != nil }

    func touch() { updatedAt = .now }
}
