import PeculeCore
import SwiftData
import SwiftUI

/// Filtres catégorie / compte / tag de la liste des transactions.
struct TransactionFilterView: View {
    @Binding var filter: TransactionFilter

    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<Category> { $0.parent == nil }, sort: [SortDescriptor(\Category.sortOrder), SortDescriptor(\Category.name)])
    private var roots: [Category]
    @Query(sort: [SortDescriptor(\Account.sortOrder), SortDescriptor(\Account.name)]) private var accounts: [Account]
    @Query(sort: \Tag.name) private var tags: [Tag]

    var body: some View {
        NavigationStack {
            List {
                Section("Comptes") {
                    ForEach(accounts) { account in
                        toggleRow(account.name, symbol: account.type.symbol, colorHex: account.colorHex, isOn: binding(account.id, in: \.accountIDs))
                    }
                }
                if !tags.isEmpty {
                    Section("Tags") {
                        ForEach(tags) { tag in
                            toggleRow(tag.name, symbol: "tag.fill", colorHex: tag.colorHex, isOn: binding(tag.id, in: \.tagIDs))
                        }
                    }
                }
                Section("Catégories") {
                    ForEach(roots) { root in
                        toggleRow(root.name, symbol: root.symbol, colorHex: root.colorHex, isOn: binding(root.id, in: \.categoryIDs))
                        ForEach(root.sortedChildren) { child in
                            toggleRow(child.name, symbol: child.symbol, colorHex: child.colorHex, isOn: binding(child.id, in: \.categoryIDs))
                                .padding(.leading, 24)
                        }
                    }
                }
            }
            .navigationTitle("Filtres")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Réinitialiser") {
                        filter = TransactionFilter(text: filter.text)
                    }
                    .disabled(filter.activeCriteriaCount == 0)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") { dismiss() }
                }
            }
        }
    }

    private func binding(_ id: UUID, in keyPath: WritableKeyPath<TransactionFilter, Set<UUID>>) -> Binding<Bool> {
        Binding(
            get: { filter[keyPath: keyPath].contains(id) },
            set: { isOn in
                if isOn { filter[keyPath: keyPath].insert(id) } else { filter[keyPath: keyPath].remove(id) }
            }
        )
    }

    private func toggleRow(_ title: String, symbol: String, colorHex: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Label {
                Text(title)
            } icon: {
                CategoryBadge(symbol: symbol, colorHex: colorHex, size: 26)
            }
        }
    }
}

#Preview {
    @Previewable @State var filter = TransactionFilter()
    TransactionFilterView(filter: $filter)
        .modelContainer(PreviewData.container())
}
