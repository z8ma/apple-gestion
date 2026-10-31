import SwiftData
import SwiftUI

/// Comptes manuels (les connexions bancaires arrivent en M3).
struct AccountsListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\Account.sortOrder), SortDescriptor(\Account.name)]) private var accounts: [Account]
    @State private var editing: Account?
    @State private var isCreating = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(active) { account in
                        row(account)
                    }
                    .onMove(perform: move)
                }
                if !archived.isEmpty {
                    Section("Archivés") {
                        ForEach(archived) { account in
                            row(account)
                        }
                    }
                }
            }
            .navigationTitle("Comptes")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isCreating = true
                    } label: {
                        Label("Nouveau compte", systemImage: "plus")
                    }
                }
            }
            .overlay {
                if accounts.isEmpty {
                    ContentUnavailableView {
                        Label("Aucun compte", systemImage: "building.columns")
                    } description: {
                        Text("Créez un compte manuel pour suivre vos dépenses.")
                    } actions: {
                        Button("Créer un compte") { isCreating = true }
                            .buttonStyle(.borderedProminent)
                    }
                }
            }
            .sheet(isPresented: $isCreating) {
                NavigationStack { AccountEditorView(account: nil) }
            }
            .sheet(item: $editing) { account in
                NavigationStack { AccountEditorView(account: account) }
            }
        }
    }

    private var active: [Account] { accounts.filter { !$0.isArchived } }
    private var archived: [Account] { accounts.filter(\.isArchived) }

    private func row(_ account: Account) -> some View {
        Button {
            editing = account
        } label: {
            HStack(spacing: 12) {
                CategoryBadge(symbol: account.type.symbol, colorHex: account.colorHex)
                VStack(alignment: .leading, spacing: 2) {
                    Text(account.name).foregroundStyle(.primary)
                    Text(account.institutionName ?? String(localized: account.type.label))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                AmountText(amount: account.balance, currency: account.currency)
            }
        }
        .swipeActions {
            Button(account.isArchived ? "Désarchiver" : "Archiver", systemImage: "archivebox") {
                account.isArchived.toggle()
                account.updatedAt = .now
                try? context.save()
            }
            .tint(.orange)
        }
    }

    private func move(from source: IndexSet, to destination: Int) {
        var ordered = active
        ordered.move(fromOffsets: source, toOffset: destination)
        for (index, account) in ordered.enumerated() where account.sortOrder != index {
            account.sortOrder = index
            account.updatedAt = .now
        }
        try? context.save()
    }
}

#Preview {
    AccountsListView()
        .modelContainer(PreviewData.container())
}
