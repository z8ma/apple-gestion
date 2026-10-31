import PeculeCore
import SwiftData
import SwiftUI

/// Choix d'une catégorie (ou d'aucune), limité aux types pertinents.
struct CategoryPickerView: View {
    @Binding var selection: Category?
    var kinds: [CategoryKind] = CategoryKind.allCases
    var allowsNone = true

    @Environment(\.dismiss) private var dismiss
    @Query(
        filter: #Predicate<Category> { $0.parent == nil && !$0.isArchived },
        sort: [SortDescriptor(\Category.sortOrder), SortDescriptor(\Category.name)]
    )
    private var roots: [Category]
    @State private var search = ""

    var body: some View {
        List {
            if allowsNone && search.isEmpty {
                Button {
                    choose(nil)
                } label: {
                    row(name: String(localized: "Aucune catégorie"), badge: CategoryBadge(category: nil, size: 28), selected: selection == nil)
                }
            }
            ForEach(visibleRoots) { root in
                Section {
                    if matches(root) {
                        Button { choose(root) } label: {
                            row(name: root.name, badge: CategoryBadge(category: root, size: 28), selected: selection?.id == root.id)
                        }
                    }
                    ForEach(root.sortedChildren.filter { !$0.isArchived && matches($0) }) { child in
                        Button { choose(child) } label: {
                            row(name: child.name, badge: CategoryBadge(category: child, size: 24), selected: selection?.id == child.id)
                                .padding(.leading, 24)
                        }
                    }
                }
            }
        }
        .navigationTitle("Catégorie")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $search, prompt: "Rechercher une catégorie")
    }

    private var visibleRoots: [Category] {
        roots.filter { root in
            kinds.contains(root.kind)
                && (matches(root) || root.sortedChildren.contains { !$0.isArchived && matches($0) })
        }
    }

    private func matches(_ category: Category) -> Bool {
        TextSearch.matches(search, in: [category.name])
    }

    private func choose(_ category: Category?) {
        selection = category
        dismiss()
    }

    private func row(name: String, badge: CategoryBadge, selected: Bool) -> some View {
        HStack(spacing: 12) {
            badge
            Text(name).foregroundStyle(.primary)
            Spacer()
            if selected {
                Image(systemName: "checkmark").foregroundStyle(.tint)
            }
        }
        .contentShape(Rectangle())
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

#Preview {
    @Previewable @State var selection: Category?
    NavigationStack {
        CategoryPickerView(selection: $selection, kinds: [.expense])
    }
    .modelContainer(PreviewContainer.make())
}
