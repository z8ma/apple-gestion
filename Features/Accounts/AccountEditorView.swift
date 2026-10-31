import PeculeCore
import SwiftData
import SwiftUI

struct AccountEditorView: View {
    /// `nil` : création.
    let account: Account?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \UserSettings.createdAt) private var settings: [UserSettings]

    @State private var name = ""
    @State private var institution = ""
    @State private var type: AccountType = .checking
    @State private var currency = SettingsDefaults.currency
    @State private var balance: Decimal? = 0
    @State private var includeInBudget = true
    @State private var sharePercent = 100
    @State private var includeInNetWorth = true
    @State private var color = Color(hex: "#5E7CE2")
    @State private var isArchived = false
    @State private var isConfirmingDelete = false
    @State private var didLoad = false

    var body: some View {
        Form {
            Section {
                TextField("Nom du compte", text: $name)
                TextField("Banque (facultatif)", text: $institution)
                Picker("Type", selection: $type) {
                    ForEach(AccountType.allCases, id: \.self) { type in
                        Label { Text(type.label) } icon: { Image(systemName: type.symbol) }.tag(type)
                    }
                }
                ColorPicker("Couleur", selection: $color, supportsOpacity: false)
            }
            Section("Solde") {
                HStack {
                    TextField("Solde", value: $balance, format: .number.precision(.fractionLength(0...2)))
                        .keyboardType(.numbersAndPunctuation)
                    Text(currency).foregroundStyle(.secondary)
                }
                Picker("Devise", selection: $currency) {
                    ForEach(Self.currencies, id: \.self) { code in
                        Text(code).tag(code)
                    }
                }
            }
            Section {
                Toggle("Inclure dans le budget", isOn: $includeInBudget)
                if includeInBudget {
                    Stepper(value: $sharePercent, in: 5...100, step: 5) {
                        LabeledContent("Part personnelle", value: "\(sharePercent) %")
                    }
                }
                Toggle("Inclure dans le patrimoine", isOn: $includeInNetWorth)
            } footer: {
                Text("Pour un compte joint, indiquez votre part : 50 % compte la moitié de chaque dépense dans votre budget.")
            }
            if let account {
                Section {
                    Toggle("Archivé", isOn: $isArchived)
                    Button("Supprimer le compte", role: .destructive) { isConfirmingDelete = true }
                } footer: {
                    Text("Supprimer un compte supprime aussi ses \((account.transactions ?? []).count) transactions. Archivez-le pour le masquer sans rien perdre.")
                }
            }
        }
        .navigationTitle(account == nil ? "Nouveau compte" : "Compte")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Annuler", role: .cancel) { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Enregistrer", action: save)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .confirmationDialog("Supprimer ce compte et ses transactions ?", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
            Button("Supprimer", role: .destructive, action: delete)
        }
        .onAppear(perform: load)
    }

    /// Devises proposées : les plus courantes d'abord, puis toutes les devises ISO.
    static let currencies: [String] = {
        let common = ["EUR", "USD", "GBP", "CHF", "CAD"]
        return common + Locale.commonISOCurrencyCodes.filter { !common.contains($0) }
    }()

    private func load() {
        guard !didLoad else { return }
        didLoad = true
        guard let account else {
            currency = settings.first?.defaultCurrency ?? SettingsDefaults.currency
            return
        }
        name = account.name
        institution = account.institutionName ?? ""
        type = account.type
        currency = account.currency
        balance = account.balance
        includeInBudget = account.includeInBudget
        sharePercent = NSDecimalNumber(decimal: account.budgetSharePercent).intValue
        includeInNetWorth = account.includeInNetWorth
        color = Color(hex: account.colorHex)
        isArchived = account.isArchived
    }

    private func save() {
        let target = account ?? {
            let created = Account(name: name, type: type, currency: currency)
            created.sortOrder = (try? context.fetchCount(FetchDescriptor<Account>())) ?? 0
            context.insert(created)
            return created
        }()
        target.name = name.trimmingCharacters(in: .whitespaces)
        let trimmedInstitution = institution.trimmingCharacters(in: .whitespaces)
        target.institutionName = trimmedInstitution.isEmpty ? nil : trimmedInstitution
        target.type = type
        target.currency = currency
        let newBalance = SignedAmount.rounded(balance ?? 0)
        if target.balance != newBalance {
            target.balance = newBalance
            target.balanceDate = .now
        }
        target.includeInBudget = includeInBudget
        target.budgetSharePercent = Decimal(sharePercent)
        target.includeInNetWorth = includeInNetWorth
        target.colorHex = color.hexString()
        target.isArchived = isArchived
        target.updatedAt = .now
        try? context.save()
        dismiss()
    }

    private func delete() {
        guard let account else { return }
        context.delete(account)
        try? context.save()
        dismiss()
    }
}

#Preview("Création") {
    NavigationStack { AccountEditorView(account: nil) }
        .modelContainer(PreviewData.container())
}
