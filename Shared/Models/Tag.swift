import Foundation
import SwiftData

@Model
final class Tag {
    var id: UUID = UUID()
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now

    var name: String = ""
    var colorHex: String = "#2D9CDB"

    @Relationship(deleteRule: .nullify, inverse: \Transaction.tags)
    var transactions: [Transaction]? = []
    @Relationship(deleteRule: .nullify, inverse: \Rule.addTags)
    var rules: [Rule]? = []

    init(name: String, colorHex: String = "#2D9CDB") {
        self.name = name
        self.colorHex = colorHex
    }
}
