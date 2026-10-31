import SwiftData
import SwiftUI

/// Gestion des tags libres (ex. « Vacances Italie »).
struct TagsListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Tag.name) private var tags: [Tag]
    @State private var editing: Tag?
    @State private var isCreating = false

    var body: some View {
        List {
            ForEach(tags) { tag in
                Button {
                    editing = tag
                } label: {
                    HStack {
                        Circle().fill(Color(hex: tag.colorHex)).frame(width: 14, height: 14)
                        Text(tag.name).foregroundStyle(.primary)
                        Spacer()
                        Text("\((tag.transactions ?? []).count)")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
                .swipeActions {
                    Button("Supprimer", systemImage: "trash", role: .destructive) {
                        context.delete(tag)
                        try? context.save()
                    }
                }
            }
        }
        .navigationTitle("Tags")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { isCreating = true } label: { Label("Nouveau tag", systemImage: "plus") }
            }
        }
        .overlay {
            if tags.isEmpty {
                ContentUnavailableView("Aucun tag", systemImage: "tag", description: Text("Les tags regroupent des transactions de catégories différentes, par exemple un voyage."))
            }
        }
        .sheet(isPresented: $isCreating) { NavigationStack { TagEditorView(tag: nil) } }
        .sheet(item: $editing) { tag in NavigationStack { TagEditorView(tag: tag) } }
    }
}

struct TagEditorView: View {
    let tag: Tag?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var colorHex = AppearanceCatalog.colors[1]
    @State private var didLoad = false

    var body: some View {
        Form {
            TextField("Nom du tag", text: $name)
            Section("Couleur") { ColorHexPicker(hex: $colorHex) }
        }
        .navigationTitle(tag == nil ? "Nouveau tag" : "Tag")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Annuler", role: .cancel) { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Enregistrer", action: save).disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .onAppear {
            guard !didLoad, let tag else { return }
            didLoad = true
            name = tag.name
            colorHex = tag.colorHex
        }
    }

    private func save() {
        let target = tag ?? {
            let created = Tag(name: name)
            context.insert(created)
            return created
        }()
        target.name = name.trimmingCharacters(in: .whitespaces)
        target.colorHex = colorHex
        target.updatedAt = .now
        try? context.save()
        dismiss()
    }
}

#Preview {
    NavigationStack { TagsListView() }
        .modelContainer(PreviewData.container())
}
