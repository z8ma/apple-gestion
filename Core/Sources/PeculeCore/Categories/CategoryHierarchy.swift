import Foundation

/// Règles d'édition des catégories (SPEC B.6 : un seul niveau de sous-catégorie,
/// catégories système renommables mais non supprimables).
public enum CategoryHierarchy {
    public struct Node: Sendable {
        public let id: UUID
        public let kind: CategoryKind
        public let parentID: UUID?
        public let hasChildren: Bool

        public init(id: UUID, kind: CategoryKind, parentID: UUID?, hasChildren: Bool) {
            self.id = id
            self.kind = kind
            self.parentID = parentID
            self.hasChildren = hasChildren
        }
    }

    public enum Issue: Error, Equatable, Sendable {
        /// Une catégorie ne peut pas être son propre parent.
        case selfParent
        /// Le parent choisi est lui-même une sous-catégorie (un seul niveau).
        case parentIsSubcategory
        /// La catégorie a des sous-catégories : elle ne peut pas devenir enfant.
        case hasChildren
        /// Parent et enfant doivent être du même type (dépense, revenu…).
        case kindMismatch
    }

    /// Vérifie qu'on peut rattacher `child` à `parent` (`nil` = catégorie principale).
    public static func validate(child: Node, parent: Node?) -> Issue? {
        guard let parent else { return nil }
        if parent.id == child.id { return .selfParent }
        if parent.parentID != nil { return .parentIsSubcategory }
        if child.hasChildren { return .hasChildren }
        if parent.kind != child.kind { return .kindMismatch }
        return nil
    }

    public static func canDelete(isSystem: Bool) -> Bool { !isSystem }

    /// Nom non vide et absent parmi les catégories sœurs (casse et accents ignorés).
    public static func isNameAvailable(_ name: String, among siblings: [String]) -> Bool {
        let normalized = TextSearch.normalize(name)
        guard !normalized.isEmpty else { return false }
        return !siblings.contains { TextSearch.normalize($0) == normalized }
    }

    /// Nouveaux `sortOrder` après un déplacement (sémantique de `onMove`).
    public static func reorder<ID: Hashable>(_ ids: [ID], from source: IndexSet, to destination: Int) -> [ID: Int] {
        var moved = ids
        let items = source.sorted().map { ids[$0] }
        for index in source.sorted(by: >) { moved.remove(at: index) }
        let insertion = destination - source.filter { $0 < destination }.count
        moved.insert(contentsOf: items, at: min(max(insertion, 0), moved.count))
        return Dictionary(uniqueKeysWithValues: moved.enumerated().map { ($1, $0) })
    }
}
