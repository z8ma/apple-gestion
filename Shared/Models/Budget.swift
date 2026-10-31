import Foundation
import SwiftData

/// Cible mensuelle d'une catégorie (mode `.categoryMonthly`, M4).
/// `periodStart == nil` : valeur récurrente ; renseigné : surcharge pour cette période.
@Model
final class BudgetTarget {
    var id: UUID = UUID()
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now

    var category: Category?
    var amount: Decimal = 0
    var periodStart: Date?

    init(category: Category, amount: Decimal, periodStart: Date? = nil) {
        self.category = category
        self.amount = amount
        self.periodStart = periodStart
    }
}

/// Enveloppe (mode `.envelopes`, M4).
@Model
final class Envelope {
    var id: UUID = UUID()
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now

    var name: String = ""
    @Relationship(deleteRule: .nullify, inverse: \Category.envelopes)
    var categories: [Category]? = []
    var symbol: String = "envelope.fill"
    var colorHex: String = "#5E7CE2"
    /// Report du reste ou du dépassement sur la période suivante.
    var rolloverEnabled: Bool = false

    @Relationship(deleteRule: .cascade, inverse: \EnvelopeAllocation.envelope)
    var allocations: [EnvelopeAllocation]? = []

    init(name: String) {
        self.name = name
    }
}

@Model
final class EnvelopeAllocation {
    var id: UUID = UUID()
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now

    var envelope: Envelope?
    var periodStart: Date = Date.now
    var amount: Decimal = 0

    init(envelope: Envelope, periodStart: Date, amount: Decimal) {
        self.envelope = envelope
        self.periodStart = periodStart
        self.amount = amount
    }
}
