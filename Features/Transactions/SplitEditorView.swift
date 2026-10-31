import PeculeCore
import SwiftData
import SwiftUI

/// Division d'une transaction en N parts catégorisées. Enregistrement impossible tant que
/// la somme des parts diffère du montant (SplitValidation).
struct SplitEditorView: View {
    let transaction: Transaction

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \UserSettings.createdAt) private var settings: [UserSettings]
    @State private var parts: [SplitPartDraft] = []
    @State private var didLoad = false
    @State private var isConfirmingRemoval = false

    var body: some View {
        Form {
            Section {
                LabeledContent("Montant total") {
                    AmountText(amount: transaction.amount, currency: transaction.currency)
                }
                LabeledContent("Reste à répartir") {
                    Text(remaining, format: .currency(code: transaction.currency))
                        .monospacedDigit()
                        .foregroundStyle(remaining == 0 ? Color.green : Color.orange)
                }
            } footer: {
                if let message = issueMessage { Text(message).foregroundStyle(.orange) }
            }

            ForEach($parts) { $part in
                Section {
                    HStack {
                        TextField("Montant", value: $part.magnitude, format: .number.precision(.fractionLength(0...2)))
                            .keyboardType(.decimalPad)
                        Text(transaction.currency).foregroundStyle(.secondary)
                    }
                    NavigationLink {
                        CategoryPickerView(selection: $part.category, kinds: CategoryKind.allowed(for: transaction.kind))
                    } label: {
                        HStack {
                            CategoryBadge(category: part.category, size: 22)
                            Text(part.category?.fullName ?? String(localized: "Choisir une catégorie"))
                                .foregroundStyle(part.category == nil ? .secondary : .primary)
                        }
                    }
                    Picker("Nature", selection: $part.nature) {
                        Text("Aucune").tag(String?.none)
                        ForEach(natureLabels, id: \.self) { Text($0).tag(Optional($0)) }
                    }
                    TextField("Libellé (facultatif)", text: $part.label)
                } header: {
                    HStack {
                        Text("Part \((parts.firstIndex { $0.id == part.id } ?? 0) + 1)")
                        Spacer()
                        if parts.count > 2 {
                            Button("Retirer", role: .destructive) {
                                parts.removeAll { $0.id == part.id }
                            }
                            .font(.caption)
                        }
                    }
                }
            }

            Section {
                Button("Ajouter une part", systemImage: "plus") {
                    parts.append(SplitPartDraft(magnitude: remaining.magnitude > 0 ? remaining.magnitude : nil))
                }
                Button("Répartir équitablement", systemImage: "equal.circle") {
                    let even = SplitValidation.evenParts(total: transaction.amount, count: parts.count)
                    for index in parts.indices { parts[index].magnitude = even[index].magnitude }
                }
                if transaction.isSplitParent {
                    Button("Annuler la division", systemImage: "arrow.uturn.backward", role: .destructive) {
                        isConfirmingRemoval = true
                    }
                }
            }
        }
        .navigationTitle("Diviser")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Enregistrer", action: save).disabled(!isValid)
            }
        }
        .confirmationDialog("Annuler la division ?", isPresented: $isConfirmingRemoval, titleVisibility: .visible) {
            Button("Supprimer les parts", role: .destructive, action: removeSplit)
        } message: {
            Text("La transaction redevient une seule ligne, à catégoriser.")
        }
        .onAppear(perform: load)
    }

    private var natureLabels: [String] { settings.first?.natureLabels ?? SettingsDefaults.natureLabels }

    /// Montants signés comme le parent (une part d'une dépense est une dépense).
    private var signedParts: [Decimal] {
        parts.map { part in
            let value = SignedAmount.rounded((part.magnitude ?? 0).magnitude)
            return transaction.amount < 0 ? -value : value
        }
    }

    private var remaining: Decimal { SplitValidation.remaining(total: transaction.amount, parts: signedParts) }
    private var issues: [SplitValidation.Issue] { SplitValidation.issues(total: transaction.amount, parts: signedParts) }
    private var isValid: Bool { issues.isEmpty }

    private var issueMessage: String? {
        guard let issue = issues.first else { return nil }
        switch issue {
        case .notEnoughParts: return String(localized: "Il faut au moins deux parts.")
        case .zeroPart(let index): return String(localized: "La part \(index + 1) est vide.")
        case .signMismatch: return String(localized: "Toutes les parts doivent avoir le même sens que la transaction.")
        case .sumMismatch: return String(localized: "La somme des parts doit être égale au montant total.")
        }
    }

    private func load() {
        guard !didLoad else { return }
        didLoad = true
        let existing = (transaction.splits ?? []).sorted { $0.createdAt < $1.createdAt }
        if existing.isEmpty {
            let even = SplitValidation.evenParts(total: transaction.amount, count: 2)
            parts = [
                SplitPartDraft(magnitude: even[0].magnitude, category: transaction.category, nature: transaction.nature),
                SplitPartDraft(magnitude: even[1].magnitude),
            ]
        } else {
            parts = existing.map {
                SplitPartDraft(magnitude: $0.amount.magnitude, category: $0.category, nature: $0.nature,
                               label: $0.displayName == transaction.displayName ? "" : $0.displayName)
            }
        }
    }

    private func save() {
        guard isValid else { return }
        for old in transaction.splits ?? [] { context.delete(old) }
        for (part, amount) in zip(parts, signedParts) {
            let label = part.label.trimmingCharacters(in: .whitespaces)
            let child = Transaction(amount: amount, date: transaction.date, label: label.isEmpty ? transaction.displayName : label,
                                    kind: transaction.kind, source: transaction.source, currency: transaction.currency,
                                    account: transaction.account)
            child.rawLabel = transaction.rawLabel
            child.merchantKey = transaction.merchantKey
            child.status = transaction.status
            child.category = part.category
            child.categorizationOrigin = part.category == nil ? .none : .user
            child.needsReview = part.category == nil
            child.nature = part.nature
            child.tags = transaction.tags
            child.excludedFromBudget = transaction.excludedFromBudget
            child.parent = transaction
            context.insert(child)
        }
        transaction.category = nil
        transaction.needsReview = false
        transaction.touch()
        try? context.save()
        dismiss()
    }

    private func removeSplit() {
        let first = (transaction.splits ?? []).sorted { $0.createdAt < $1.createdAt }.first
        transaction.category = first?.category
        transaction.categorizationOrigin = first?.category == nil ? .none : .user
        transaction.needsReview = transaction.category == nil
        for part in transaction.splits ?? [] { context.delete(part) }
        transaction.touch()
        try? context.save()
        dismiss()
    }
}

struct SplitPartDraft: Identifiable {
    let id = UUID()
    var magnitude: Decimal?
    var category: Category?
    var nature: String?
    var label = ""
}

#Preview {
    let container = PreviewData.container()
    let transaction = (try? container.mainContext.fetch(FetchDescriptor<Transaction>()))?.first { $0.amount < 0 }
    NavigationStack {
        if let transaction { SplitEditorView(transaction: transaction) }
    }
    .modelContainer(container)
}
