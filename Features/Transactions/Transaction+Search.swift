import Foundation
import PeculeCore

extension Transaction {
    /// Champs de recherche, incluant ceux des parts d'un split.
    var searchFields: TransactionSearchFields {
        let parts = [self] + (splits ?? [])
        var categoryIDs = Set<UUID>()
        for category in parts.compactMap(\.category) {
            categoryIDs.insert(category.id)
            if let parent = category.parent { categoryIDs.insert(parent.id) }
        }
        let allTags = parts.flatMap { $0.tags ?? [] }
        let texts = [displayName, rawLabel, note ?? "", account?.name ?? ""]
            + parts.compactMap { $0.category?.name }
            + allTags.map(\.name)
        return TransactionSearchFields(
            texts: texts,
            categoryIDs: categoryIDs,
            accountID: account?.id,
            tagIDs: Set(allTags.map(\.id)),
            amount: amount,
            date: date
        )
    }

    /// Flux comptés : la transaction elle-même, ou ses parts si elle est divisée.
    var flowItems: [FlowItem] {
        let parts = isSplitParent ? (splits ?? []) : [self]
        return parts.map { FlowItem(amount: $0.amount, kind: $0.kind, date: $0.date) }
    }
}
