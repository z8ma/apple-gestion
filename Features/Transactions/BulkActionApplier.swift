import Foundation
import PeculeCore
import SwiftData

/// Applique une `BulkAction` (logique pure dans PeculeCore) aux modèles SwiftData.
enum BulkActionApplier {
    static func apply(_ action: BulkAction, to transactions: [Transaction], in context: ModelContext) throws {
        let categories = try categoriesByID(for: action, in: context)
        let tags = try Dictionary(context.fetch(FetchDescriptor<Tag>()).map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

        for transaction in transactions {
            // Pour une transaction divisée, exclusion et tags valent aussi pour ses parts.
            let propagated = transaction.isSplitParent && action.propagatesToSplitParts ? (transaction.splits ?? []) : []
            for target in [transaction] + propagated {
                guard let result = action.applied(to: target.bulkTarget) else {
                    context.delete(target)
                    continue
                }
                update(target, with: result, categories: categories, tags: tags)
            }
        }
        try context.save()
    }

    private static func update(_ transaction: Transaction, with result: BulkTarget, categories: [UUID: Category], tags: [UUID: Tag]) {
        if result.categoryID != transaction.category?.id {
            transaction.category = result.categoryID.flatMap { categories[$0] }
        }
        transaction.categorizationOrigin = result.categorizationOrigin
        transaction.needsReview = result.needsReview
        let currentTags = transaction.tags ?? []
        if Set(currentTags.map(\.id)) != result.tagIDs {
            transaction.tags = result.tagIDs.compactMap { id in tags[id] ?? currentTags.first { $0.id == id } }
        }
        transaction.excludedFromBudget = result.excludedFromBudget
        transaction.nature = result.nature
        transaction.touch()
    }

    private static func categoriesByID(for action: BulkAction, in context: ModelContext) throws -> [UUID: Category] {
        guard case .categorize(let id?) = action else { return [:] }
        let found = try context.fetch(FetchDescriptor<Category>(predicate: #Predicate { $0.id == id }))
        return Dictionary(found.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }
}

extension BulkAction {
    var propagatesToSplitParts: Bool {
        switch self {
        case .addTags, .removeTags, .setExcludedFromBudget, .setNature: true
        case .categorize, .delete: false
        }
    }
}

extension Transaction {
    var bulkTarget: BulkTarget {
        BulkTarget(
            categoryID: category?.id,
            tagIDs: Set((tags ?? []).map(\.id)),
            excludedFromBudget: excludedFromBudget,
            nature: nature,
            categorizationOrigin: categorizationOrigin,
            needsReview: needsReview,
            isSplitParent: isSplitParent
        )
    }
}
