import PeculeCore
import SwiftData
import SwiftUI

/// Sélection multiple de tags, avec création à la volée.
struct TagPickerView: View {
    @Binding var selection: [Tag]

    @Environment(\.modelContext) private var context
    @Query(sort: \Tag.name) private var tags: [Tag]
    @State private var newTagName = ""

    var body: some View {
        List {
            Section {
                HStack {
                    TextField("Nouveau tag", text: $newTagName)
                        .submitLabel(.done)
                        .onSubmit(createTag)
                    Button("Ajouter", action: createTag)
                        .disabled(trimmedName.isEmpty)
                }
            }
            Section {
                ForEach(tags) { tag in
                    Button {
                        toggle(tag)
                    } label: {
                        HStack {
                            Circle().fill(Color(hex: tag.colorHex)).frame(width: 12, height: 12)
                            Text(tag.name).foregroundStyle(.primary)
                            Spacer()
                            if isSelected(tag) {
                                Image(systemName: "checkmark").foregroundStyle(.tint)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .accessibilityAddTraits(isSelected(tag) ? .isSelected : [])
                }
            } footer: {
                if tags.isEmpty {
                    Text("Les tags regroupent des transactions de catégories différentes, par exemple « Vacances Italie ».")
                }
            }
        }
        .navigationTitle("Tags")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var trimmedName: String {
        newTagName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func isSelected(_ tag: Tag) -> Bool {
        selection.contains { $0.id == tag.id }
    }

    private func toggle(_ tag: Tag) {
        if isSelected(tag) {
            selection.removeAll { $0.id == tag.id }
        } else {
            selection.append(tag)
        }
    }

    private func createTag() {
        let name = trimmedName
        guard !name.isEmpty else { return }
        if let existing = tags.first(where: { TextSearch.normalize($0.name) == TextSearch.normalize(name) }) {
            if !isSelected(existing) { selection.append(existing) }
        } else {
            let tag = Tag(name: name)
            context.insert(tag)
            selection.append(tag)
        }
        newTagName = ""
    }
}

#Preview {
    @Previewable @State var selection: [Tag] = []
    NavigationStack {
        TagPickerView(selection: $selection)
    }
    .modelContainer(PreviewData.container())
}
