import SwiftUI

/// Choix d'une couleur (palette + sélecteur libre).
struct ColorHexPicker: View {
    @Binding var hex: String

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 7), spacing: 10) {
            ForEach(AppearanceCatalog.colors, id: \.self) { candidate in
                Button {
                    hex = candidate
                } label: {
                    Circle()
                        .fill(Color(hex: candidate))
                        .frame(height: 32)
                        .overlay {
                            if candidate == hex {
                                Image(systemName: "checkmark").font(.caption.bold()).foregroundStyle(.white)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(candidate))
                .accessibilityAddTraits(candidate == hex ? .isSelected : [])
            }
        }
        .padding(.vertical, 4)
        ColorPicker("Autre couleur", selection: Binding(
            get: { Color(hex: hex) },
            set: { hex = $0.hexString() }
        ), supportsOpacity: false)
    }
}

/// Choix d'un SF Symbol dans le catalogue.
struct SymbolPicker: View {
    @Binding var symbol: String
    let colorHex: String

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
            ForEach(AppearanceCatalog.symbols, id: \.self) { candidate in
                Button {
                    symbol = candidate
                } label: {
                    CategoryBadge(symbol: candidate, colorHex: candidate == symbol ? colorHex : "#9E9E9E", size: 40)
                        .overlay {
                            if candidate == symbol {
                                Circle().stroke(Color(hex: colorHex), lineWidth: 2)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(candidate))
                .accessibilityAddTraits(candidate == symbol ? .isSelected : [])
            }
        }
        .padding(.vertical, 4)
    }
}
