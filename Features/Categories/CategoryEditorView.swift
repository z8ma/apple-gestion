import PeculeCore
import SwiftData
import SwiftUI

struct CategoryEditorView: View {
    /// `nil` : création.
    let category: Category?
    let defaultKind: CategoryKind
    /// Parent imposé à la création (ajout depuis l'écran des sous-catégories).
    var presetParent: Category?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<Category> { $0.parent == nil && !$0.isArchived }, sort: [SortDescriptor(\Category.sortOrder), SortDescriptor(\Category.name)])
    private var roots: [Category]

    @State private var name = ""
    @State private var symbol = "tag.fill"
    @State private var colorHex = AppearanceCatalog.colors[0]
    @State private var kind: CategoryKind = .expense
    @State private var parent: Category?
    @State private var didLoad = false

    var body: some View {
        Form {
            Section {
                HStack {
                    Spacer()
                    CategoryBadge(symbol: symbol, colorHex: colorHex, size: 64)
                    Spacer()
                }
                .listRowBackground(Color.clear)
                TextField("Nom", text: $name)
            } footer: {
                if let message = validationMessage { Text(message).foregroundStyle(.orange) }
            }
            if canChangeKind {
                Section {
                    Picker("Type", selection: $kind) {
                        ForEach(CategoryKind.allCases, id: \.self) { Text($0.label).tag($0) }
                    }
                }
            }
            Section {
                Picker("Catégorie parente", selection: $parent) {
                    Text("Aucune (catégorie principale)").tag(Category?.none)
                    ForEach(parentCandidates) { candidate in
                        Text(candidate.name).tag(Optional(candidate))
                    }
                }
                .disabled(hasChildren)
            } footer: {
                if hasChildren {
                    Text("Une catégorie qui a des sous-catégories reste une catégorie principale.")
                }
            }
            Section("Couleur") { ColorHexPicker(hex: $colorHex) }
            Section("Icône") { SymbolPicker(symbol: $symbol, colorHex: colorHex) }
        }
        .navigationTitle(category == nil ? "Nouvelle catégorie" : "Catégorie")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Annuler", role: .cancel) { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Enregistrer", action: save).disabled(validationMessage != nil)
            }
        }
        .onAppear(perform: load)
        .onChange(of: parent) { _, newParent in
            if let newParent { kind = newParent.kind }
        }
    }

    private var hasChildren: Bool { !(category?.children ?? []).isEmpty }
    /// Le type d'une catégorie système, ou d'une sous-catégorie (hérité du parent), est figé.
    private var canChangeKind: Bool { !(category?.isSystem ?? false) && parent == nil }

    private var parentCandidates: [Category] {
        roots.filter { $0.id != category?.id && $0.kind == kind }
    }

    private var siblingsNames: [String] {
        let siblings = parent?.children ?? roots
        return siblings.filter { $0.id != category?.id }.map(\.name)
    }

    private var validationMessage: String? {
        if name.trimmingCharacters(in: .whitespaces).isEmpty { return String(localized: "Donnez un nom à la catégorie.") }
        if !CategoryHierarchy.isNameAvailable(name, among: siblingsNames) { return String(localized: "Une catégorie porte déjà ce nom à ce niveau.") }
        if let issue = CategoryHierarchy.validate(child: node, parent: parent.map(Self.node)) {
            switch issue {
            case .selfParent: return String(localized: "Une catégorie ne peut pas être sa propre parente.")
            case .parentIsSubcategory: return String(localized: "Une sous-catégorie ne peut pas avoir d'enfant.")
            case .hasChildren: return String(localized: "Cette catégorie a des sous-catégories.")
            case .kindMismatch: return String(localized: "La catégorie parente doit être du même type.")
            }
        }
        return nil
    }

    private var node: CategoryHierarchy.Node {
        CategoryHierarchy.Node(id: category?.id ?? UUID(), kind: kind, parentID: parent?.id, hasChildren: hasChildren)
    }

    private static func node(_ category: Category) -> CategoryHierarchy.Node {
        CategoryHierarchy.Node(id: category.id, kind: category.kind, parentID: category.parent?.id, hasChildren: !(category.children ?? []).isEmpty)
    }

    private func load() {
        guard !didLoad else { return }
        didLoad = true
        guard let category else {
            kind = defaultKind
            parent = presetParent
            if let presetParent {
                symbol = presetParent.symbol
                colorHex = presetParent.colorHex
            }
            return
        }
        name = category.name
        symbol = category.symbol
        colorHex = category.colorHex
        kind = category.kind
        parent = category.parent
    }

    private func save() {
        let target = category ?? {
            let created = Category(name: name, symbol: symbol, colorHex: colorHex, kind: kind)
            created.sortOrder = (parent?.children ?? roots).count
            context.insert(created)
            return created
        }()
        target.name = name.trimmingCharacters(in: .whitespaces)
        target.symbol = symbol
        target.colorHex = colorHex
        target.kind = kind
        target.parent = parent
        for child in target.children ?? [] where child.kind != kind {
            child.kind = kind
        }
        target.updatedAt = .now
        try? context.save()
        dismiss()
    }
}

#Preview {
    NavigationStack { CategoryEditorView(category: nil, defaultKind: .expense) }
        .modelContainer(PreviewContainer.make())
}
