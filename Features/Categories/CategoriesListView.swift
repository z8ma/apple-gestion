import PeculeCore
import SwiftData
import SwiftUI

/// Gestion des catégories principales : création, édition, réordonnancement, archivage.
/// Les sous-catégories se gèrent dans `SubcategoriesView`.
struct CategoriesListView: View {
    enum Scope: Hashable, CaseIterable {
        case expense, income, other

        var kinds: [CategoryKind] {
            switch self {
            case .expense: [.expense]
            case .income: [.income]
            case .other: [.transfer, .saving]
            }
        }

        var label: LocalizedStringKey {
            switch self {
            case .expense: "Dépenses"
            case .income: "Revenus"
            case .other: "Autres"
            }
        }
    }

    @Query(filter: #Predicate<Category> { $0.parent == nil }, sort: [SortDescriptor(\Category.sortOrder), SortDescriptor(\Category.name)])
    private var roots: [Category]

    @State private var scope: Scope = .expense
    @State private var showsArchived = false
    @State private var isCreating = false
    @State private var actions = CategoryActions()

    var body: some View {
        List {
            Section {
                Picker("Type", selection: $scope) {
                    ForEach(Scope.allCases, id: \.self) { Text($0.label).tag($0) }
                }
                .pickerStyle(.segmented)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())

            Section {
                ForEach(visibleRoots) { root in
                    NavigationLink(value: root) {
                        CategoryRow(category: root, subtitle: childrenSummary(root))
                    }
                    .categorySwipeActions(root, actions: $actions)
                }
                .onMove { actions.move(visibleRoots, from: $0, to: $1) }
            }

            Section {
                Toggle("Afficher les catégories archivées", isOn: $showsArchived)
            }
        }
        .navigationTitle("Catégories")
        .navigationDestination(for: Category.self) { SubcategoriesView(parent: $0) }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { isCreating = true } label: { Label("Nouvelle catégorie", systemImage: "plus") }
            }
            ToolbarItem(placement: .topBarTrailing) { EditButton() }
        }
        .sheet(isPresented: $isCreating) {
            NavigationStack { CategoryEditorView(category: nil, defaultKind: scope.kinds[0]) }
        }
        .categoryDeletionDialog(actions: $actions)
    }

    private var visibleRoots: [Category] {
        roots.filter { scope.kinds.contains($0.kind) && (showsArchived || !$0.isArchived) }
    }

    private func childrenSummary(_ root: Category) -> String? {
        let names = root.sortedChildren.filter { !$0.isArchived }.map(\.name)
        return names.isEmpty ? nil : names.joined(separator: ", ")
    }
}

/// Une catégorie principale et ses sous-catégories.
struct SubcategoriesView: View {
    let parent: Category

    @State private var editing: Category?
    @State private var isCreating = false
    @State private var showsArchived = false
    @State private var actions = CategoryActions()

    var body: some View {
        List {
            Section {
                Button { editing = parent } label: {
                    CategoryRow(category: parent, subtitle: String(localized: "Modifier la catégorie"))
                }
            }
            Section("Sous-catégories") {
                ForEach(children) { child in
                    Button { editing = child } label: { CategoryRow(category: child) }
                        .categorySwipeActions(child, actions: $actions)
                }
                .onMove { actions.move(children, from: $0, to: $1) }
                Button("Ajouter une sous-catégorie", systemImage: "plus") { isCreating = true }
            }
            Section {
                Toggle("Afficher les sous-catégories archivées", isOn: $showsArchived)
            }
        }
        .navigationTitle(parent.name)
        .toolbar { EditButton() }
        .sheet(item: $editing) { category in
            NavigationStack { CategoryEditorView(category: category, defaultKind: category.kind) }
        }
        .sheet(isPresented: $isCreating) {
            NavigationStack { CategoryEditorView(category: nil, defaultKind: parent.kind, presetParent: parent) }
        }
        .categoryDeletionDialog(actions: $actions)
    }

    private var children: [Category] {
        parent.sortedChildren.filter { showsArchived || !$0.isArchived }
    }
}

struct CategoryRow: View {
    let category: Category
    var subtitle: String?

    var body: some View {
        HStack(spacing: 12) {
            CategoryBadge(category: category, size: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(category.name)
                    .foregroundStyle(category.isArchived ? .secondary : .primary)
                if let subtitle {
                    Text(subtitle).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
            }
            Spacer()
            if category.isArchived {
                Image(systemName: "archivebox").foregroundStyle(.secondary).accessibilityLabel("Archivée")
            }
            if category.isSystem {
                Image(systemName: "lock.fill").font(.caption).foregroundStyle(.tertiary).accessibilityLabel("Catégorie système")
            }
        }
    }
}

/// Actions partagées des listes de catégories (archivage, suppression, ordre).
struct CategoryActions {
    var pendingDeletion: Category?

    func move(_ items: [Category], from source: IndexSet, to destination: Int) {
        let orders = CategoryHierarchy.reorder(items.map(\.id), from: source, to: destination)
        for category in items {
            if let order = orders[category.id], order != category.sortOrder {
                category.sortOrder = order
                category.updatedAt = .now
            }
        }
        try? items.first?.modelContext?.save()
    }

    func toggleArchived(_ category: Category) {
        category.isArchived.toggle()
        category.updatedAt = .now
        try? category.modelContext?.save()
    }

    /// Supprime une catégorie non système ; ses transactions (et celles de ses enfants)
    /// repassent « à catégoriser ».
    mutating func delete(_ category: Category) {
        defer { pendingDeletion = nil }
        guard CategoryHierarchy.canDelete(isSystem: category.isSystem), let context = category.modelContext else { return }
        for affected in [category] + (category.children ?? []) {
            for transaction in affected.transactions ?? [] {
                transaction.needsReview = true
                transaction.categorizationOrigin = .none
            }
        }
        context.delete(category)
        try? context.save()
    }
}

extension View {
    func categorySwipeActions(_ category: Category, actions: Binding<CategoryActions>) -> some View {
        swipeActions {
            if CategoryHierarchy.canDelete(isSystem: category.isSystem) {
                Button("Supprimer", systemImage: "trash", role: .destructive) {
                    actions.wrappedValue.pendingDeletion = category
                }
            }
            Button(category.isArchived ? "Désarchiver" : "Archiver", systemImage: "archivebox") {
                actions.wrappedValue.toggleArchived(category)
            }
            .tint(.orange)
        }
    }

    func categoryDeletionDialog(actions: Binding<CategoryActions>) -> some View {
        confirmationDialog(
            "Supprimer « \(actions.wrappedValue.pendingDeletion?.name ?? "") » ?",
            isPresented: Binding(
                get: { actions.wrappedValue.pendingDeletion != nil },
                set: { if !$0 { actions.wrappedValue.pendingDeletion = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Supprimer", role: .destructive) {
                if let category = actions.wrappedValue.pendingDeletion {
                    actions.wrappedValue.delete(category)
                }
            }
        } message: {
            Text("Ses transactions repasseront « à catégoriser » et ses sous-catégories seront supprimées. Archivez-la pour la masquer sans rien perdre.")
        }
    }
}

#Preview {
    NavigationStack { CategoriesListView() }
        .modelContainer(PreviewContainer.make())
}
