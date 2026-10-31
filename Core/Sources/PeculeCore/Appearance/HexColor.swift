import Foundation

/// Couleur `#RRGGBB` (stockage des couleurs choisies par l'utilisateur).
public struct HexColor: Equatable, Sendable {
    public var red: Double
    public var green: Double
    public var blue: Double

    public init(red: Double, green: Double, blue: Double) {
        self.red = Self.clamp(red)
        self.green = Self.clamp(green)
        self.blue = Self.clamp(blue)
    }

    /// Accepte `#RRGGBB`, `RRGGBB`, `#RGB` (casse indifférente). `nil` si invalide.
    public init?(_ string: String) {
        var hex = string.trimmingCharacters(in: .whitespaces)
        if hex.hasPrefix("#") { hex.removeFirst() }
        if hex.count == 3 { hex = hex.map { "\($0)\($0)" }.joined() }
        guard hex.count == 6, let value = UInt32(hex, radix: 16) else { return nil }
        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }

    /// Forme canonique `#RRGGBB` en majuscules.
    public var hexString: String {
        String(format: "#%02X%02X%02X", Self.byte(red), Self.byte(green), Self.byte(blue))
    }

    private static func clamp(_ v: Double) -> Double { min(max(v, 0), 1) }
    private static func byte(_ v: Double) -> Int { Int((clamp(v) * 255).rounded()) }
}
