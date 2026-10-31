import Foundation
import Testing
@testable import PeculeCore

@Suite("Actions groupées")
struct BulkActionTests {
    let food = UUID(), tagA = UUID(), tagB = UUID()

    var target: BulkTarget {
        BulkTarget(categoryID: nil, tagIDs: [tagA], excludedFromBudget: false, nature: nil,
                   categorizationOrigin: .none, needsReview: true, isSplitParent: false)
    }

    @Test("Catégoriser : origine utilisateur, plus à revoir")
    func categorize() {
        let result = BulkAction.categorize(categoryID: food).applied(to: target)
        #expect(result?.categoryID == food)
        #expect(result?.categorizationOrigin == .user)
        #expect(result?.needsReview == false)
        let cleared = BulkAction.categorize(categoryID: nil).applied(to: result!)
        #expect(cleared?.categorizationOrigin == CategorizationOrigin.none)
        #expect(cleared?.needsReview == true)
    }

    @Test("Un parent de split n'est pas catégorisé directement")
    func splitParent() {
        var parent = target
        parent.isSplitParent = true
        #expect(BulkAction.categorize(categoryID: food).applied(to: parent) == parent)
    }

    @Test("Tags ajoutés ou retirés sans toucher aux autres")
    func tags() {
        #expect(BulkAction.addTags([tagB]).applied(to: target)?.tagIDs == [tagA, tagB])
        #expect(BulkAction.addTags([tagA]).applied(to: target)?.tagIDs == [tagA])
        #expect(BulkAction.removeTags([tagA]).applied(to: target)?.tagIDs == [])
    }

    @Test("Exclure du budget, nature, suppression")
    func others() {
        #expect(BulkAction.setExcludedFromBudget(true).applied(to: target)?.excludedFromBudget == true)
        #expect(BulkAction.setNature("Plaisir").applied(to: target)?.nature == "Plaisir")
        #expect(BulkAction.delete.applied(to: target) == nil)
        #expect(BulkAction.delete.isDestructive)
        #expect(!BulkAction.addTags([]).isDestructive)
    }
}
