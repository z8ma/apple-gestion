import Foundation

/// Recherche texte insensible à la casse et aux accents (« cafe » trouve « Café »).
public enum TextSearch {
    public static func normalize(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: Locale(identifier: "fr_FR"))
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Vrai si chaque mot de la requête apparaît dans au moins un des champs.
    public static func matches(_ query: String, in fields: [String]) -> Bool {
        let words = normalize(query).split(whereSeparator: \.isWhitespace)
        guard !words.isEmpty else { return true }
        let haystack = fields.map(normalize)
        return words.allSatisfy { word in haystack.contains { $0.contains(word) } }
    }
}
