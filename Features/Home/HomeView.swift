import PeculeCore
import SwiftData
import SwiftUI

/// Accueil : période en cours, entrées/sorties, dernières transactions, à catégoriser.
/// Le « reste à dépenser » arrivera avec les budgets (M4).
struct HomeView: View {
    @Query(sort: \UserSettings.createdAt) private var settings: [UserSettings]
    @Query(filter: #Predicate<Transaction> { $0.parent == nil }, sort: \Transaction.date, order: .reverse)
    private var transactions: [Transaction]
    @State private var isCreating = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    PeriodSummaryCard(period: period, summary: summary, currency: currency)
                }
                if !toReview.isEmpty {
                    Section("À catégoriser") {
                        ForEach(toReview.prefix(5)) { transaction in
                            NavigationLink(value: transaction) { TransactionRow(transaction: transaction) }
                        }
                    }
                }
                Section("Dernières transactions") {
                    ForEach(transactions.prefix(8)) { transaction in
                        NavigationLink(value: transaction) { TransactionRow(transaction: transaction) }
                    }
                }
            }
            .navigationTitle("Accueil")
            .navigationDestination(for: Transaction.self) { TransactionEditorView(transaction: $0) }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isCreating = true
                    } label: {
                        Label("Nouvelle transaction", systemImage: "plus")
                    }
                }
            }
            .overlay {
                if transactions.isEmpty {
                    ContentUnavailableView(
                        "Bienvenue dans Pécule",
                        systemImage: "eurosign.circle",
                        description: Text("Créez un compte puis ajoutez votre première dépense.")
                    )
                }
            }
            .sheet(isPresented: $isCreating) {
                NavigationStack { TransactionEditorView() }
            }
        }
    }

    private var currency: String { settings.first?.defaultCurrency ?? SettingsDefaults.currency }
    private var period: BudgetPeriod { (settings.first?.period()) ?? BudgetPeriod.containing(.now, startDay: 1, calendar: .current) }
    private var summary: CashFlowSummary {
        CashFlowSummary.compute(transactions.filter { $0.currency == currency }.flatMap(\.flowItems), in: period)
    }
    private var toReview: [Transaction] { transactions.filter(\.needsReview) }
}

private struct PeriodSummaryCard: View {
    let period: BudgetPeriod
    let summary: CashFlowSummary
    let currency: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(periodLabel)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack {
                metric("Sorties", summary.outflow)
                Spacer()
                metric("Entrées", summary.inflow)
            }
            Divider()
            LabeledContent("Solde de la période") {
                AmountText(amount: summary.net, currency: currency)
                    .font(.headline)
            }
        }
        .padding(.vertical, 4)
    }

    private var periodLabel: String {
        let end = period.end.addingTimeInterval(-1)
        return String(localized: "Du \(period.start.formatted(.dateTime.day().month())) au \(end.formatted(.dateTime.day().month()))")
    }

    private func metric(_ title: LocalizedStringKey, _ value: Decimal) -> some View {
        VStack(alignment: .leading) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value, format: .currency(code: currency))
                .font(.title2.weight(.semibold))
                .monospacedDigit()
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(PreviewData.container())
}
