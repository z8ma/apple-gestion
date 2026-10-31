import PeculeCore
import SwiftData
import SwiftUI

/// Liste des transactions groupée par jour, avec recherche et filtres.
struct TransactionsListView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<Transaction> { $0.parent == nil }, sort: \Transaction.date, order: .reverse)
    private var transactions: [Transaction]
    @Query(sort: \UserSettings.createdAt) private var settings: [UserSettings]

    @State private var filter = TransactionFilter()
    @State private var isShowingFilters = false
    @State private var isCreating = false

    // Multi-sélection
    @State private var editMode: EditMode = .inactive
    @State private var selectedIDs: Set<Transaction.ID> = []
    @State private var isPickingCategory = false
    @State private var isPickingTags = false
    @State private var isConfirmingDelete = false

    var body: some View {
        NavigationStack {
            List(selection: $selectedIDs) {
                ForEach(groups) { group in
                    Section {
                        ForEach(group.items) { transaction in
                            NavigationLink(value: transaction) {
                                TransactionRow(transaction: transaction)
                            }
                            .tag(transaction.id)
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
            .environment(\.editMode, $editMode)
            .toolbar {
                if isSelecting {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(allVisibleSelected ? "Tout désélectionner" : "Tout sélectionner") {
                            selectedIDs = allVisibleSelected ? [] : Set(visibleTransactions.map(\.id))
                        }
                    }
                    ToolbarItem(placement: .principal) {
                        Text("\(selectedIDs.count) sélectionnée(s)").font(.headline)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("OK") { endSelection() }
                    }
                    if !selectedIDs.isEmpty {
                        BulkActionsBar(
                            natureLabels: settings.first?.natureLabels ?? SettingsDefaults.natureLabels,
                            perform: perform,
                            isPickingCategory: $isPickingCategory,
                            isPickingTags: $isPickingTags,
                            isConfirmingDelete: $isConfirmingDelete
                        )
                    }
                } else {
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
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Sélectionner") { editMode = .active }
                            .disabled(transactions.isEmpty)
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            isCreating = true
                        } label: {
                            Label("Nouvelle transaction", systemImage: "plus")
                        }
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
            .sheet(isPresented: $isPickingCategory) {
                NavigationStack {
                    CategoryPickerView(
                        selection: Binding(get: { nil }, set: { perform(.categorize(categoryID: $0?.id)) }),
                        allowsNone: true
                    )
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Annuler", role: .cancel) { isPickingCategory = false }
                        }
                    }
                }
            }
            .sheet(isPresented: $isPickingTags) {
                BulkTagSheet { perform(.addTags($0)) }
            }
            .confirmationDialog(
                "Supprimer \(selectedIDs.count) transaction(s) ?",
                isPresented: $isConfirmingDelete,
                titleVisibility: .visible
            ) {
                Button("Supprimer", role: .destructive) { perform(.delete) }
            } message: {
                Text("Cette action est définitive.")
            }
        }
    }

    private var isSelecting: Bool { editMode.isEditing }

    private var visibleTransactions: [Transaction] {
        filter.isEmpty ? transactions : transactions.filter { filter.matches($0.searchFields) }
    }

    private var groups: [DayGroup<Transaction>] {
        DayGrouping.group(visibleTransactions, date: { $0.date }, calendar: .current)
    }

    private var selectedTransactions: [Transaction] {
        transactions.filter { selectedIDs.contains($0.id) }
    }

    private var allVisibleSelected: Bool {
        !visibleTransactions.isEmpty && visibleTransactions.allSatisfy { selectedIDs.contains($0.id) }
    }

    private func perform(_ action: BulkAction) {
        try? BulkActionApplier.apply(action, to: selectedTransactions, in: context)
        if action.isDestructive { selectedIDs = [] }
        if action.isDestructive || selectedIDs.isEmpty { endSelection() }
    }

    private func endSelection() {
        editMode = .inactive
        selectedIDs = []
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
