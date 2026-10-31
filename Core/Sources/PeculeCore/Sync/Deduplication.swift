import Foundation

/// Dédoublonnage générique d'enregistrements synchronisés par CloudKit
/// (pas de contrainte d'unicité possible : CLAUDE.md, contraintes SwiftData + CloudKit).
public enum Deduplication {
    public struct Group<Element> {
        /// Enregistrement conservé : le plus ancien (puis plus petit identifiant, pour être
        /// déterministe sur tous les appareils).
        public let keeper: Element
        /// Doublons à fusionner dans `keeper` puis à supprimer.
        public let duplicates: [Element]
    }

    /// Regroupe `items` par `key` et ne renvoie que les groupes ayant des doublons.
    public static func groups<Element, Key: Hashable>(
        _ items: [Element],
        key: (Element) -> Key?,
        createdAt: (Element) -> Date,
        id: (Element) -> UUID
    ) -> [Group<Element>] {
        var buckets: [Key: [Element]] = [:]
        var order: [Key] = []
        for item in items {
            guard let k = key(item) else { continue }
            if buckets[k] == nil { order.append(k) }
            buckets[k, default: []].append(item)
        }
        return order.compactMap { k in
            guard let bucket = buckets[k], bucket.count > 1 else { return nil }
            let sorted = bucket.sorted {
                let (a, b) = (createdAt($0), createdAt($1))
                return a != b ? a < b : id($0).uuidString < id($1).uuidString
            }
            return Group(keeper: sorted[0], duplicates: Array(sorted.dropFirst()))
        }
    }
}
