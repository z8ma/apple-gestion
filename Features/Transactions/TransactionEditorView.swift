import PeculeCore
import SwiftData
import SwiftUI

/// Création ou détail/édition d'une transaction.
struct TransactionEditorView: View {
    /// `nil` : création.
    let transaction: Transaction?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<Account> { !$0.isArchived }, sort: [SortDescriptor(\Account.sortOrder), SortDescriptor(\Account.name)])
    private var accounts: [Account]
    @Query(sort: \UserSettings.createdAt) private var settings: [UserSettings]

    @State private var draft: TransactionDraft
    @State private var isConfirmingDelete = false
    @FocusState private var amountFocused: Bool

    init(transaction: Transaction? = nil, account: Account? = nil) {
        self.transaction = transaction
        _draft = State(initialValue: transaction.map(TransactionDraft.init) ?? TransactionDraft(account: account))
    }

    private var isCreating: Bool { transaction == nil }
    private var currentSettings: UserSettings? { settings.first }
    private var currency: String {
        draft.account?.currency ?? currentSettings?.defaultCurrency ?? SettingsDefaults.currency
    }
    private var natureLabels: [String] {
        currentSettings?.natureLabels ?? SettingsDefaults.natureLabels
    }
    private var isAmountLocked: Bool { transaction?.isSplitParent ?? false }

    var body: some View {
        Form {
            amountSection
            detailsSection
            classificationSection
            Section("Note") {
                TextField("Ajouter une note", text: $draft.note, axis: .vertical)
                    .lineLimit(1...5)
            }
            Section {
                Toggle("Exclure du budget", isOn: $draft.excludedFromBudget)
            } footer: {
                Text("Une transaction exclue reste visible mais ne compte pas dans le budget ni les analyses.")
            }
            if let transaction {
                infoSection(transaction)
                Section {
                    Button("Supprimer la transaction", role: .destructive) {
                        isConfirmingDelete = true
                    }
                }
            }
        }
        .navigationTitle(isCreating ? "Nouvelle transaction" : "Transaction")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isCreating {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler", role: .cancel) { dismiss() }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Enregistrer", action: save)
                    .disabled(!draft.isValid)
            }
        }
        .confirmationDialog("Supprimer cette transaction ?", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
            Button("Supprimer", role: .destructive, action: delete)
        } message: {
            Text("Cette action est définitive.")
        }
        .onAppear {
            if isCreating { amountFocused = true }
        }
    }

    private var amountSection: some View {
        Section {
            Picker("Type", selection: $draft.kind) {
                ForEach(TransactionKind.allCases, id: \.self) { kind in
                    Text(kind.label).tag(kind)
                }
            }
            .pickerStyle(.segmented)
            .listRowSeparator(.hidden)
            HStack {
                TextField("0,00", value: $draft.magnitude, format: .number.precision(.fractionLength(0...2)))
                    .keyboardType(.decimalPad)
                    .font(.system(.largeTitle, design: .rounded, weight: .semibold))
                    .focused($amountFocused)
                    .disabled(isAmountLocked)
                Text(currency).foregroundStyle(.secondary)
            }
            if draft.kind == .transfer {
                Picker("Sens", selection: $draft.isOutgoing) {
                    Text("Sortant").tag(true)
                    Text("Entrant").tag(false)
                }
            }
        } footer: {
            if isAmountLocked {
                Text("Le montant d'une transaction divisée se modifie depuis sa répartition.")
            }
        }
    }

    private var detailsSection: some View {
        Section {
            TextField("Libellé", text: $draft.label)
                .textInputAutocapitalization(.sentences)
            DatePicker("Date", selection: $draft.date, displayedComponents: [.date, .hourAndMinute])
            Picker("Compte", selection: $draft.account) {
                Text("Aucun").tag(Account?.none)
                ForEach(accounts) { account in
                    Text(account.name).tag(Optional(account))
                }
            }
        }
    }

    private var classificationSection: some View {
        Section {
            NavigationLink {
                CategoryPickerView(selection: $draft.category, kinds: CategoryKind.allowed(for: draft.kind))
            } label: {
                HStack {
                    Text("Catégorie")
                    Spacer()
                    if let category = draft.category {
                        CategoryBadge(category: category, size: 22)
                        Text(category.fullName).foregroundStyle(.secondary)
                    } else {
                        Text("Aucune").foregroundStyle(.secondary)
                    }
                }
            }
            Picker("Nature", selection: $draft.nature) {
                Text("Aucune").tag(String?.none)
                ForEach(natureLabels, id: \.self) { label in
                    Text(label).tag(Optional(label))
                }
            }
            NavigationLink {
                TagPickerView(selection: $draft.tags)
            } label: {
                HStack {
                    Text("Tags")
                    Spacer()
                    Text(draft.tags.isEmpty ? String(localized: "Aucun") : draft.tags.map(\.name).formatted(.list(type: .and)))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        } footer: {
            if !draft.categoryMatchesKind {
                Text("Cette catégorie ne correspond pas au type d'opération choisi.")
                    .foregroundStyle(.orange)
            }
        }
    }

    private func infoSection(_ transaction: Transaction) -> some View {
        Section("Informations") {
            LabeledContent("Source") { Text(transaction.source.label) }
            if transaction.rawLabel != transaction.displayName && !transaction.rawLabel.isEmpty {
                LabeledContent("Libellé d'origine", value: transaction.rawLabel)
            }
            if let card = transaction.cardName {
                LabeledContent("Carte", value: card)
            }
        }
    }

    private func save() {
        let defaultCurrency = currentSettings?.defaultCurrency ?? SettingsDefaults.currency
        let target: Transaction
        if let transaction {
            target = transaction
        } else {
            target = Transaction(amount: 0, label: draft.trimmedLabel, kind: draft.kind, source: .manual)
            context.insert(target)
        }
        draft.apply(to: target, defaultCurrency: defaultCurrency)
        try? context.save()
        dismiss()
    }

    private func delete() {
        guard let transaction else { return }
        context.delete(transaction)
        try? context.save()
        dismiss()
    }
}

#Preview("Création") {
    NavigationStack {
        TransactionEditorView()
    }
    .modelContainer(PreviewData.container())
}

#Preview("Édition") {
    let container = PreviewData.container()
    let transaction = (try? container.mainContext.fetch(FetchDescriptor<Transaction>()))?.first
    NavigationStack {
        TransactionEditorView(transaction: transaction)
    }
    .modelContainer(container)
}
