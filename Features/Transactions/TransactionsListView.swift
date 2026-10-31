import PeculeCore
import SwiftData
import SwiftUI

/// Liste des transactions groupée par jour, avec recherche et filtres.
struct TransactionsListView: View {
    @Query(filter: #Predicate<Transaction> { $0.parent == nil }, sort: \Transaction.date, order: .reverse)
    private var transactions: [Transaction]

    @State private var filter = TransactionFilter()
    @State private var isShowingFilters = false
    @State private var isCreating = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(groups) { group in
                    Section {
                        ForEach(group.items) { transaction in
                            NavigationLink(value: transaction) {
                                TransactionRow(transaction: transaction)
                            }
                        }
                    } header: {
                        DayHeader(day: group.day, transactions: group.items)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Transactions")
            .navigationDestination(for: Transaction.self) { transaction in
                TransactionEditorView(transaction: transaction)
            }
            .searchable(text: $filter.text, prompt: "Libellé, montant, note, tag…")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        isShowingFilters = true
                    } label: {
                        Label("Filtres", systemImage: filter.activeCriteriaCount > 0
                              ? "line.3.horizontal.decrease.circle.fill"
                              : "line.3.horizontal.decrease.circle")
                    }
                    .badge(filter.activeCriteriaCount)
                }
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
                    ContentUnavailableView {
                        Label("Aucune transaction", systemImage: "list.bullet.rectangle")
                    } description: {
                        Text("Ajoutez votre première dépense avec le bouton +.")
                    }
                } else if groups.isEmpty {
                    ContentUnavailableView.search(text: filter.text)
                }
            }
            .sheet(isPresented: $isShowingFilters) {
                TransactionFilterView(filter: $filter)
            }
            .sheet(isPresented: $isCreating) {
                NavigationStack {
                    TransactionEditorView()
                }
            }
        }
    }

    private var groups: [DayGroup<Transaction>] {
        let visible = filter.isEmpty ? transactions : transactions.filter { filter.matches($0.searchFields) }
        return DayGrouping.group(visible, date: { $0.date }, calendar: .current)
    }
}

private struct DayHeader: View {
    let day: Date
    let transactions: [Transaction]

    var body: some View {
        HStack {
            Text(day, format: .dateTime.weekday(.wide).day().month(.wide))
            Spacer()
            if let currency = transactions.first?.currency, transactions.allSatisfy({ $0.currency == currency }) {
                Text(total, format: .currency(code: currency))
                    .monospacedDigit()
            }
        }
    }

    private var total: Decimal {
        transactions.filter { $0.kind != .transfer }.reduce(0) { $0 + $1.amount }
    }
}

#Preview {
    TransactionsListView()
        .modelContainer(PreviewData.container())
}
