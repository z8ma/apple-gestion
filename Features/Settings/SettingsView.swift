import PeculeCore
import SwiftData
import SwiftUI

/// Réglages : tout `UserSettings` éditable, catégories, tags (SPEC B.7, écran 8).
struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \UserSettings.createdAt) private var settingsList: [UserSettings]

    var body: some View {
        NavigationStack {
            Group {
                if let settings = settingsList.first {
                    SettingsForm(settings: settings)
                } else {
                    ProgressView()
                        .task { _ = try? SettingsStore.current(in: context) }
                }
            }
            .navigationTitle("Réglages")
        }
    }
}

private struct SettingsForm: View {
    @Bindable var settings: UserSettings
    @Environment(\.modelContext) private var context

    var body: some View {
        Form {
            Section {
                Picker("Début de période", selection: $settings.periodStartDay) {
                    ForEach(Array(BudgetPeriod.allowedStartDays), id: \.self) { day in
                        Text(day == 1 ? String(localized: "Le 1er du mois") : String(localized: "Le \(day) du mois")).tag(day)
                    }
                }
                LabeledContent("Période en cours", value: periodDescription)
                Picker("Devise par défaut", selection: $settings.defaultCurrency) {
                    ForEach(AccountEditorView.currencies, id: \.self) { code in
                        Text(currencyLabel(code)).tag(code)
                    }
                }
            } header: {
                Text("Budget")
            } footer: {
                Text("Exemple : si votre salaire arrive le 27, choisissez le 27 pour que chaque période aille d'un salaire au suivant.")
            }

            Section("Classement") {
                NavigationLink("Catégories") { CategoriesListView() }
                NavigationLink("Tags") { TagsListView() }
                NavigationLink {
                    NatureLabelsView(settings: settings)
                } label: {
                    LabeledContent("Natures", value: settings.natureLabels.joined(separator: ", "))
                }
            }

            SecuritySection(settings: settings)

            #if DEBUG
            Section("Développement") {
                NavigationLink("Données de démo") { DemoDataView() }
            }
            #endif

            Section {
                LabeledContent("Version", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—")
            }
        }
        .onChange(of: settings.periodStartDay) { touch() }
        .onChange(of: settings.defaultCurrency) { touch() }
    }

    private var periodDescription: String {
        let period = settings.period()
        let end = period.end.addingTimeInterval(-1)
        return "\(period.start.formatted(.dateTime.day().month())) – \(end.formatted(.dateTime.day().month()))"
    }

    private func currencyLabel(_ code: String) -> String {
        guard let name = Locale.current.localizedString(forCurrencyCode: code) else { return code }
        return "\(code) – \(name)"
    }

    private func touch() {
        settings.updatedAt = .now
        try? context.save()
    }
}

/// Libellés de la « nature » (défaut : Essentiel, Plaisir, Épargne), éditables.
struct NatureLabelsView: View {
    @Bindable var settings: UserSettings
    @Environment(\.modelContext) private var context
    @State private var newLabel = ""

    var body: some View {
        List {
            Section {
                ForEach(settings.natureLabels, id: \.self) { label in
                    Text(label)
                }
                .onDelete { settings.natureLabels.remove(atOffsets: $0); save() }
                .onMove { settings.natureLabels.move(fromOffsets: $0, toOffset: $1); save() }
            } footer: {
                Text("La nature est une seconde classification, indépendante des catégories. Supprimer une nature ne modifie pas les transactions déjà classées.")
            }
            Section {
                HStack {
                    TextField("Nouvelle nature", text: $newLabel)
                        .onSubmit(add)
                    Button("Ajouter", action: add).disabled(!canAdd)
                }
            }
            Section {
                Button("Rétablir les natures par défaut") {
                    settings.natureLabels = SettingsDefaults.natureLabels
                    save()
                }
            }
        }
        .navigationTitle("Natures")
        .toolbar { EditButton() }
    }

    private var trimmed: String { newLabel.trimmingCharacters(in: .whitespaces) }
    private var canAdd: Bool { !trimmed.isEmpty && !settings.natureLabels.contains(trimmed) }

    private func add() {
        guard canAdd else { return }
        settings.natureLabels.append(trimmed)
        newLabel = ""
        save()
    }

    private func save() {
        settings.updatedAt = .now
        try? context.save()
    }
}

/// Verrouillage par Face ID / Touch ID / code.
struct SecuritySection: View {
    @Bindable var settings: UserSettings
    @Environment(AppLockController.self) private var lock
    @Environment(\.modelContext) private var context
    @State private var isConfirming = false

    var body: some View {
        Section {
            Toggle(isOn: Binding(get: { settings.lockWithBiometrics }, set: setLock)) {
                Label {
                    Text("Verrouiller avec \(String(localized: method.label))")
                } icon: {
                    Image(systemName: method.symbol)
                }
            }
            .disabled(method == .unavailable || isConfirming)
        } header: {
            Text("Sécurité")
        } footer: {
            if method == .unavailable {
                Text("Configurez un code sur l'iPhone pour activer le verrouillage.")
            } else {
                Text("L'app se verrouille quand elle passe en arrière-plan, et son contenu est masqué dans le sélecteur d'apps.")
            }
        }
    }

    private var method: AuthenticationMethod { lock.availableMethod }

    private func setLock(_ enabled: Bool) {
        guard enabled else {
            apply(false)
            return
        }
        isConfirming = true
        Task {
            let confirmed = await lock.confirmIdentity()
            isConfirming = false
            if confirmed { apply(true) }
        }
    }

    private func apply(_ enabled: Bool) {
        settings.lockWithBiometrics = enabled
        settings.updatedAt = .now
        try? context.save()
        lock.handle(.enabledChanged(enabled))
    }
}

#if DEBUG
/// Menu debug : génération de 6 mois de données de démo, remise à zéro.
struct DemoDataView: View {
    @Environment(\.modelContext) private var context
    @State private var message: String?
    @State private var isConfirmingErase = false

    var body: some View {
        Form {
            Section {
                Button("Générer 6 mois de données", systemImage: "wand.and.stars") {
                    run {
                        let summary = try DemoDataImporter.importDemo(into: context)
                        return String(localized: "\(summary.transactions) transactions et \(summary.accounts) comptes créés.")
                    }
                }
            } footer: {
                Text("Crée trois comptes (courant, joint à 50 %, Livret A) et des transactions réalistes : charges, salaire, courses, voyage tagué, remboursements, virements, achats à catégoriser.")
            }
            Section {
                Button("Tout effacer", systemImage: "trash", role: .destructive) { isConfirmingErase = true }
            } footer: {
                Text("Supprime toutes les données de cet appareil et d'iCloud, puis recrée les catégories par défaut.")
            }
            if let message {
                Section { Text(message).foregroundStyle(.secondary) }
            }
        }
        .navigationTitle("Données de démo")
        .confirmationDialog("Effacer toutes les données ?", isPresented: $isConfirmingErase, titleVisibility: .visible) {
            Button("Tout effacer", role: .destructive) {
                run { try DemoDataImporter.eraseAll(in: context); return String(localized: "Toutes les données ont été effacées.") }
            }
        }
    }

    private func run(_ action: () throws -> String) {
        do {
            message = try action()
        } catch {
            message = String(localized: "Échec : \(error.localizedDescription)")
        }
    }
}
#endif

#Preview {
    SettingsView()
        .modelContainer(PreviewContainer.make())
        .environment(AppLockController(isEnabled: false, authenticator: FakeDeviceAuthenticator()))
}

#Preview("Natures") {
    let container = PreviewContainer.make()
    let settings = try? SettingsStore.current(in: container.mainContext)
    NavigationStack {
        if let settings { NatureLabelsView(settings: settings) }
    }
    .modelContainer(container)
}

#if DEBUG
#Preview("Données de démo") {
    NavigationStack { DemoDataView() }
        .modelContainer(PreviewContainer.make())
}
#endif
