import Foundation
import Testing
@testable import PeculeCore

@Suite("Split d'une transaction")
struct SplitValidationTests {
    let total = Decimal.exact("-100.00")

    @Test("Somme égale au montant : valide")
    func valid() {
        #expect(SplitValidation.isValid(total: total, parts: [.exact("-60"), .exact("-40")]))
        #expect(SplitValidation.isValid(total: .exact("-0.03"), parts: [.exact("-0.01"), .exact("-0.02")]))
    }

    @Test("Impossible d'enregistrer si la somme des parts ≠ montant", arguments: [
        ([Decimal.exact("-60"), .exact("-39.99")], Decimal.exact("-0.01")),
        ([Decimal.exact("-60"), .exact("-50")], Decimal.exact("10")),
    ])
    func sumMismatch(parts: [Decimal], remaining: Decimal) {
        let issues = SplitValidation.issues(total: total, parts: parts)
        #expect(issues == [.sumMismatch(remaining: remaining)])
        #expect(!SplitValidation.isValid(total: total, parts: parts))
    }

    @Test("Au moins deux parts")
    func minimumParts() {
        #expect(SplitValidation.issues(total: total, parts: [total]) == [.notEnoughParts])
        #expect(SplitValidation.issues(total: total, parts: []).contains(.notEnoughParts))
    }

    @Test("Part nulle ou de signe opposé refusée")
    func partSigns() {
        #expect(SplitValidation.issues(total: total, parts: [.exact("-100"), 0]) == [.zeroPart(index: 1)])
        #expect(SplitValidation.issues(total: total, parts: [.exact("-120"), .exact("20")]) == [.signMismatch(index: 1)])
        #expect(SplitValidation.isValid(total: .exact("50"), parts: [.exact("20"), .exact("30")]))
    }

    @Test("Pas d'erreur d'arrondi binaire : 0,1 + 0,2 = 0,3")
    func decimalPrecision() {
        #expect(SplitValidation.isValid(total: .exact("-0.3"), parts: [.exact("-0.1"), .exact("-0.2")]))
    }

    @Test("Parts égales au centime, somme exacte", arguments: [
        (Decimal.exact("-100"), 3, [Decimal.exact("-33.34"), .exact("-33.33"), .exact("-33.33")]),
        (Decimal.exact("10"), 4, [Decimal.exact("2.5"), .exact("2.5"), .exact("2.5"), .exact("2.5")]),
        (Decimal.exact("-0.05"), 2, [Decimal.exact("-0.03"), .exact("-0.02")]),
        (Decimal.exact("-0.01"), 3, [Decimal.exact("-0.01"), 0, 0]),
    ])
    func evenParts(total: Decimal, count: Int, expected: [Decimal]) {
        let parts = SplitValidation.evenParts(total: total, count: count)
        #expect(parts == expected)
        #expect(parts.reduce(0, +) == total)
    }

    @Test("Propriété : la répartition égale tombe toujours juste", arguments: 2...7)
    func evenPartsProperty(count: Int) {
        for cents in [1, 7, 99, 100, 1_001, 123_457] {
            let total = Decimal(-cents) / 100
            #expect(SplitValidation.evenParts(total: total, count: count).reduce(0, +) == total)
        }
        #expect(SplitValidation.evenParts(total: 10, count: 0).isEmpty)
    }
}

@Suite("Remboursements")
struct RefundValidationTests {
    let expense = RefundValidation.Side(id: UUID(), amount: .exact("-42"), currency: "EUR")

    func refund(_ amount: String, currency: String = "EUR") -> RefundValidation.Side {
        RefundValidation.Side(id: UUID(), amount: .exact(amount), currency: currency)
    }

    @Test("Remboursement valide d'une dépense")
    func valid() {
        #expect(RefundValidation.validate(refund: refund("12"), original: expense) == nil)
        #expect(!RefundValidation.exceedsOriginal(refund: refund("42"), original: expense))
        #expect(RefundValidation.exceedsOriginal(refund: refund("42.01"), original: expense))
    }

    @Test("Refus : même transaction, montant négatif, original non dépense, devises différentes")
    func invalid() {
        #expect(RefundValidation.validate(refund: expense, original: expense) == .sameTransaction)
        #expect(RefundValidation.validate(refund: refund("-12"), original: expense) == .refundNotPositive)
        #expect(RefundValidation.validate(refund: refund("12"), original: refund("30")) == .originalNotExpense)
        #expect(RefundValidation.validate(refund: refund("12", currency: "USD"), original: expense) == .currencyMismatch)
    }
}
