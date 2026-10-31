import Foundation

/// Action groupée sur une sélection de transactions (SPEC B.7, écran 2).
public enum BulkAction: Equatable, Sendable {
    case categorize(categoryID: UUID?)
    case addTags(Set<UUID>)
    case removeTags(Set<UUID>)
    case setExcludedFromBudget(Bool)
    case setNature(String?)
    case delete
}

/// État minimal d'une transaction concerné par les actions groupées.
public struct BulkTarget: Equatable, Sendable {
    public var categoryID: UUID?
    public var tagIDs: Set<UUID>
    public var excludedFromBudget: Bool
    public var nature: String?
    public var categorizationOrigin: CategorizationOrigin
    public var needsReview: Bool
    /// Un parent de split n'a pas de catégorie propre : ses parts en ont.
    public var isSplitParent: Bool

    public init(categoryID: UUID?, tagIDs: Set<UUID>, excludedFromBudget: Bool, nature: String?,
                categorizationOrigin: CategorizationOrigin, needsReview: Bool, isSplitParent: Bool) {
        self.categoryID = categoryID
        self.tagIDs = tagIDs
        self.excludedFromBudget = excludedFromBudget
        self.nature = nature
        self.categorizationOrigin = categorizationOrigin
        self.needsReview = needsReview
        self.isSplitParent = isSplitParent
    }
}

extension BulkAction {
    /// Résultat de l'action sur une transaction ; `nil` pour une suppression.
    public func applied(to target: BulkTarget) -> BulkTarget? {
        var result = target
        switch self {
        case .categorize(let categoryID):
            guard !target.isSplitParent else { return target }
            result.categoryID = categoryID
            result.categorizationOrigin = categoryID == nil ? .none : .user
            result.needsReview = categoryID == nil
        case .addTags(let ids):
            result.tagIDs.formUnion(ids)
        case .removeTags(let ids):
            result.tagIDs.subtract(ids)
        case .setExcludedFromBudget(let excluded):
            result.excludedFromBudget = excluded
        case .setNature(let nature):
            result.nature = nature
        case .delete:
            return nil
        }
        return result
    }

    /// L'action demande-t-elle une confirmation ?
    public var isDestructive: Bool { self == .delete }
}
