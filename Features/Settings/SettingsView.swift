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
                        .task { try? SettingsStore.current(in: context) }
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

/// Section Sécurité (complétée par feature/M1-verrouillage).
struct SecuritySection: View {
    @Bindable var settings: UserSettings

    var body: some View {
        EmptyView()
    }
}

#if DEBUG
/// Menu debug (complété par feature/M1-donnees-demo).
struct DemoDataView: View {
    var body: some View {
        ContentUnavailableView("Données de démo", systemImage: "wand.and.stars")
    }
}
#endif

#Preview {
    SettingsView()
        .modelContainer(PreviewContainer.make())
}
