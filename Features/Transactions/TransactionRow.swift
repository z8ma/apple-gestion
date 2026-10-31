import SwiftData
import SwiftUI

struct TransactionRow: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: 12) {
            CategoryBadge(category: transaction.isSplitParent ? nil : transaction.category)
                .overlay(alignment: .bottomTrailing) {
                    if transaction.needsReview {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .background(Circle().fill(.background))
                    }
                }
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.displayName)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 2) {
                AmountText(amount: transaction.amount, currency: transaction.currency, kind: transaction.kind)
                HStack(spacing: 4) {
                    if transaction.isSplitParent {
                        Image(systemName: "arrow.triangle.branch").accessibilityLabel("Divisée")
                    }
                    if transaction.excludedFromBudget {
                        Image(systemName: "eye.slash").accessibilityLabel("Exclue du budget")
                    }
                    if !(transaction.tags ?? []).isEmpty {
                        Image(systemName: "tag").accessibilityLabel("Taguée")
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var subtitle: String {
        if transaction.isSplitParent {
            return String(localized: "Divisée en \((transaction.splits ?? []).count) parts")
        }
        let category = transaction.category?.name ?? String(localized: "À catégoriser")
        guard let account = transaction.account?.name else { return category }
        return "\(category) · \(account)"
    }
}

#Preview {
    let container = PreviewData.container()
    let transactions = (try? container.mainContext.fetch(FetchDescriptor<Transaction>())) ?? []
    List(transactions) { TransactionRow(transaction: $0) }
        .modelContainer(container)
}
