import Foundation
import Testing
@testable import PeculeCore

@Suite("Données de démo")
struct DemoDataGeneratorTests {
    static let calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Europe/Paris")!
        return c
    }()
    static let end = calendar.date(from: DateComponents(year: 2026, month: 10, day: 31, hour: 22))!
    static let dataset = DemoDataGenerator.make(months: 6, endingAt: end, calendar: calendar)

    @Test("Déterministe : même graine, mêmes données ; autre graine, autres données")
    func deterministic() {
        #expect(DemoDataGenerator.make(months: 6, endingAt: Self.end, calendar: Self.calendar) == Self.dataset)
        #expect(DemoDataGenerator.make(months: 6, endingAt: Self.end, calendar: Self.calendar, seed: 7) != Self.dataset)
    }

    @Test("Six mois de transactions réalistes")
    func coverage() {
        let tx = Self.dataset.transactions
        #expect(tx.count > 250)
        #expect(tx.allSatisfy { $0.date >= Self.dataset.start && $0.date <= Self.end })
        #expect(tx.filter { $0.categoryKey == "income.salary" }.count == 6)
        #expect(tx.filter { $0.label.hasPrefix("Loyer") }.count == 6)
        #expect(zip(tx, tx.dropFirst()).allSatisfy { $0.date <= $1.date })
    }

    @Test("Signes et précision : dépenses < 0, revenus et remboursements > 0, au centime")
    func amounts() {
        for t in Self.dataset.transactions {
            #expect(SignedAmount.rounded(t.amount) == t.amount)
            switch t.kind {
            case .expense: #expect(t.amount < 0)
            case .income, .refund: #expect(t.amount > 0)
            case .transfer: #expect(t.amount != 0)
            }
        }
    }

    @Test("Catégories, comptes et tags référencés existent")
    func references() {
        let keys = Set(DefaultCategories.flattened.map(\.seed.key))
        let accounts = Set(Self.dataset.accounts.map(\.key))
        for t in Self.dataset.transactions {
            if let key = t.categoryKey { #expect(keys.contains(key), "\(key)") }
            #expect(accounts.contains(t.accountKey))
        }
        #expect(Self.dataset.transactions.filter { $0.categoryKey == nil }.count == 3)
        #expect(Self.dataset.transactions.contains { $0.tags.contains(DemoDataGenerator.tripTag) })
        #expect(Self.dataset.transactions.contains { $0.accountKey == "joint" })
    }

    @Test("Virements internes équilibrés entre deux comptes")
    func transfers() {
        let transfers = Self.dataset.transactions.filter { $0.kind == .transfer }
        #expect(!transfers.isEmpty)
        #expect(transfers.reduce(0) { $0 + $1.amount } == 0)
        #expect(Set(transfers.map(\.accountKey)) == ["checking", "savings"])
    }

    @Test("Remboursements liés à une dépense antérieure, de même catégorie, inférieurs à la dépense")
    func refunds() throws {
        let byID = Dictionary(uniqueKeysWithValues: Self.dataset.transactions.map { ($0.id, $0) })
        let refunds = Self.dataset.transactions.filter { $0.kind == .refund }
        #expect(refunds.count == 2)
        for refund in refunds {
            let original = try #require(refund.refundOf.flatMap { byID[$0] })
            #expect(original.kind == .expense)
            #expect(original.date < refund.date)
            #expect(original.categoryKey == refund.categoryKey)
            #expect(refund.amount <= original.amount.magnitude)
        }
    }

    @Test("Solde de clôture = solde d'ouverture + mouvements")
    func balances() {
        let savings = Self.dataset.transactions.filter { $0.accountKey == "savings" }.reduce(Decimal(0)) { $0 + $1.amount }
        #expect(Self.dataset.closingBalance(of: "savings") == .exact("4000") + savings)
        #expect(Self.dataset.closingBalance(of: "inconnu") == 0)
    }
}
