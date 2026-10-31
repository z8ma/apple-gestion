import CoreGraphics
import PeculeCore
import SwiftUI

extension Color {
    /// Couleur depuis `#RRGGBB` (gris si invalide).
    init(hex: String) {
        let color = HexColor(hex) ?? HexColor(red: 0.6, green: 0.6, blue: 0.6)
        self.init(.sRGB, red: color.red, green: color.green, blue: color.blue)
    }

    /// `#RRGGBB` dans l'espace sRGB (pour enregistrer un choix de `ColorPicker`).
    func hexString(in environment: EnvironmentValues = EnvironmentValues()) -> String {
        let resolved = resolve(in: environment)
        guard let srgb = CGColorSpace(name: CGColorSpace.sRGB),
              let converted = resolved.cgColor.converted(to: srgb, intent: .defaultIntent, options: nil),
              let components = converted.components, components.count >= 3
        else { return "#999999" }
        return HexColor(red: Double(components[0]), green: Double(components[1]), blue: Double(components[2])).hexString
    }
}
