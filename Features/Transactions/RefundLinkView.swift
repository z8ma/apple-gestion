import PeculeCore
import SwiftData
import SwiftUI

/// Choix de la dépense qu'une transaction rembourse.
struct RefundLinkView: View {
    let refund: Transaction

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<Transaction> { $0.amount < 0 && $0.kindRaw == "expense" }, sort: \Transaction.date, order: .reverse)
    private var expenses: [Transaction]
    @State private var search = ""

    var body: some View {
        List {
            if let issue = blockingIssue {
                Section { Text(issue).foregroundStyle(.orange) }
            }
            if refund.linkedRefundOf != nil {
                Section {
                    Button("Retirer le lien de remboursement", role: .destructive) {
                        refund.linkedRefundOf = nil
                        refund.touch()
                        try? context.save()
                        dismiss()
                    }
                }
            }
            Section("Dépense remboursée") {
                ForEach(candidates) { expense in
                    Button {
                        link(to: expense)
                    } label: {
                        HStack {
                            TransactionRow(transaction: expense)
                            if refund.linkedRefundOf?.id == expense.id {
                                Image(systemName: "checkmark").foregroundStyle(.tint)
                            }
                        }
                    }
                    .foregroundStyle(.primary)
                    .disabled(blockingIssue != nil)
                }
            }
        }
        .navigationTitle("Remboursement de…")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $search, prompt: "Rechercher une dépense")
    }

    private var candidates: [Transaction] {
        expenses
            .filter { $0.id != refund.id && $0.currency == refund.currency }
            .filter { search.isEmpty || TransactionFilter(text: search).matches($0.searchFields) }
            .prefix(200)
            .map { $0 }
    }

    /// Le remboursement lui-même doit être une entrée d'argent.
    private var blockingIssue: String? {
        refund.amount > 0 ? nil : String(localized: "Un remboursement est une entrée d'argent : changez d'abord le type de cette transaction en « Remboursement ».")
    }

    private func link(to expense: Transaction) {
        let refundSide = RefundValidation.Side(id: refund.id, amount: refund.amount, currency: refund.currency)
        let originalSide = RefundValidation.Side(id: expense.id, amount: expense.amount, currency: expense.currency)
        guard RefundValidation.validate(refund: refundSide, original: originalSide) == nil else { return }
        refund.linkedRefundOf = expense
        refund.kind = .refund
        if refund.category == nil, let category = expense.category {
            refund.category = category
            refund.categorizationOrigin = .user
            refund.needsReview = false
        }
        refund.touch()
        try? context.save()
        dismiss()
    }
}
