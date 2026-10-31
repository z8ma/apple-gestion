import SwiftUI

/// Pastille ronde d'une catégorie (symbole sur fond teinté).
struct CategoryBadge: View {
    let symbol: String
    let colorHex: String
    var size: CGFloat = 34

    init(symbol: String, colorHex: String, size: CGFloat = 34) {
        self.symbol = symbol
        self.colorHex = colorHex
        self.size = size
    }

    init(category: Category?, size: CGFloat = 34) {
        self.init(symbol: category?.symbol ?? "questionmark", colorHex: category?.colorHex ?? "#9E9E9E", size: size)
    }

    var body: some View {
        let color = Color(hex: colorHex)
        Image(systemName: symbol)
            .font(.system(size: size * 0.45, weight: .semibold))
            .foregroundStyle(color)
            .frame(width: size, height: size)
            .background(color.opacity(0.16), in: Circle())
            .accessibilityHidden(true)
    }
}

#Preview {
    HStack {
        CategoryBadge(symbol: "cart.fill", colorHex: "#3FA34D")
        CategoryBadge(category: nil)
    }
}
