import PeculeCore
import SwiftData
import SwiftUI

/// Barre d'actions de la multi-sélection.
struct BulkActionsBar: ToolbarContent {
    let natureLabels: [String]
    let perform: (BulkAction) -> Void
    @Binding var isPickingCategory: Bool
    @Binding var isPickingTags: Bool
    @Binding var isConfirmingDelete: Bool

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .bottomBar) {
            Button("Catégoriser", systemImage: "square.grid.2x2") { isPickingCategory = true }
            Button("Taguer", systemImage: "tag") { isPickingTags = true }
            Menu("Plus", systemImage: "ellipsis.circle") {
                Button("Exclure du budget", systemImage: "eye.slash") { perform(.setExcludedFromBudget(true)) }
                Button("Inclure dans le budget", systemImage: "eye") { perform(.setExcludedFromBudget(false)) }
                Menu("Nature", systemImage: "circle.lefthalf.filled") {
                    ForEach(natureLabels, id: \.self) { label in
                        Button(label) { perform(.setNature(label)) }
                    }
                    Button("Aucune") { perform(.setNature(nil)) }
                }
            }
            Spacer()
            Button("Supprimer", systemImage: "trash", role: .destructive) { isConfirmingDelete = true }
        }
    }
}

/// Choix des tags à ajouter à une sélection.
struct BulkTagSheet: View {
    let apply: (Set<UUID>) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var tags: [Tag] = []

    var body: some View {
        NavigationStack {
            TagPickerView(selection: $tags)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Annuler", role: .cancel) { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Ajouter") {
                            apply(Set(tags.map(\.id)))
                            dismiss()
                        }
                        .disabled(tags.isEmpty)
                    }
                }
        }
    }
}
