import Foundation
import Testing
@testable import PeculeCore

@Suite("Hiérarchie des catégories")
struct CategoryHierarchyTests {
    let food = CategoryHierarchy.Node(id: UUID(), kind: .expense, parentID: nil, hasChildren: true)
    let salary = CategoryHierarchy.Node(id: UUID(), kind: .income, parentID: nil, hasChildren: false)

    var groceries: CategoryHierarchy.Node {
        CategoryHierarchy.Node(id: UUID(), kind: .expense, parentID: food.id, hasChildren: false)
    }

    @Test("Rattachement valide, ou catégorie principale")
    func valid() {
        let leaf = CategoryHierarchy.Node(id: UUID(), kind: .expense, parentID: nil, hasChildren: false)
        #expect(CategoryHierarchy.validate(child: leaf, parent: food) == nil)
        #expect(CategoryHierarchy.validate(child: food, parent: nil) == nil)
    }

    @Test("Refus : soi-même, sous-catégorie comme parent, enfants existants, type différent")
    func invalid() {
        #expect(CategoryHierarchy.validate(child: food, parent: food) == .selfParent)
        let leaf = CategoryHierarchy.Node(id: UUID(), kind: .expense, parentID: nil, hasChildren: false)
        #expect(CategoryHierarchy.validate(child: leaf, parent: groceries) == .parentIsSubcategory)
        let otherRoot = CategoryHierarchy.Node(id: UUID(), kind: .expense, parentID: nil, hasChildren: false)
        #expect(CategoryHierarchy.validate(child: food, parent: otherRoot) == .hasChildren)
        #expect(CategoryHierarchy.validate(child: leaf, parent: salary) == .kindMismatch)
    }

    @Test("Les catégories système ne sont pas supprimables")
    func deletion() {
        #expect(!CategoryHierarchy.canDelete(isSystem: true))
        #expect(CategoryHierarchy.canDelete(isSystem: false))
    }

    @Test("Nom disponible parmi les sœurs, casse et accents ignorés")
    func names() {
        #expect(CategoryHierarchy.isNameAvailable("Bio", among: ["Courses", "Cafés"]))
        #expect(!CategoryHierarchy.isNameAvailable("cafes", among: ["Courses", "Cafés"]))
        #expect(!CategoryHierarchy.isNameAvailable("   ", among: []))
    }

    @Test("Réordonnancement conforme à onMove", arguments: [
        (IndexSet(integer: 0), 3, ["b", "c", "a", "d"]),
        (IndexSet(integer: 3), 0, ["d", "a", "b", "c"]),
        (IndexSet([0, 1]), 4, ["c", "d", "a", "b"]),
        (IndexSet(integer: 1), 1, ["a", "b", "c", "d"]),
        (IndexSet(integer: 2), 1, ["a", "c", "b", "d"]),
    ])
    func reorder(source: IndexSet, destination: Int, expected: [String]) {
        let ids = ["a", "b", "c", "d"]
        let orders = CategoryHierarchy.reorder(ids, from: source, to: destination)
        #expect(ids.sorted { orders[$0]! < orders[$1]! } == expected)
    }
}
