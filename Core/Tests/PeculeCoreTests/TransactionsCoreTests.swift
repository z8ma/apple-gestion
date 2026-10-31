import Foundation
import Testing
@testable import PeculeCore

@Suite("Convention de signe")
struct SignedAmountTests {
    @Test("Dépense négative, revenu et remboursement positifs, quel que soit le signe saisi", arguments: [
        (Decimal(12), TransactionKind.expense, Decimal(-12)),
        (Decimal(-12), .expense, Decimal(-12)),
        (Decimal(12), .income, Decimal(12)),
        (Decimal(-12), .income, Decimal(12)),
        (Decimal(5), .refund, Decimal(5)),
    ])
    func signs(input: Decimal, kind: TransactionKind, expected: Decimal) {
        #expect(SignedAmount.make(magnitude: input, kind: kind) == expected)
    }

    @Test("Virement : le sens décide du signe")
    func transfer() {
        #expect(SignedAmount.make(magnitude: 100, kind: .transfer, outgoing: true) == -100)
        #expect(SignedAmount.make(magnitude: 100, kind: .transfer, outgoing: false) == 100)
    }

    @Test("Arrondi au centime")
    func rounding() {
        #expect(SignedAmount.rounded(Decimal(string: "12.345")!) == Decimal(string: "12.35")!)
        #expect(SignedAmount.rounded(Decimal(string: "-12.344")!) == Decimal(string: "-12.34")!)
        #expect(SignedAmount.rounded(Decimal(string: "0.1")! + Decimal(string: "0.2")!) == Decimal(string: "0.3")!)
    }

    @Test("Catégories proposées selon le type d'opération")
    func allowedKinds() {
        #expect(CategoryKind.allowed(for: .expense) == [.expense, .saving])
        #expect(CategoryKind.allowed(for: .refund) == [.expense])
        #expect(CategoryKind.allowed(for: .income) == [.income])
        #expect(CategoryKind.allowed(for: .transfer) == [.transfer, .saving])
    }
}

@Suite("Recherche et filtres")
struct FilterTests {
    let food = UUID(), groceries = UUID(), account = UUID(), other = UUID(), trip = UUID()

    func fields(texts: [String] = ["Carrefour City"], categories: Set<UUID>? = nil, account: UUID? = nil, tags: Set<UUID> = [], amount: Decimal = -12.5) -> TransactionSearchFields {
        TransactionSearchFields(texts: texts, categoryIDs: categories ?? [groceries, food], accountID: account ?? self.account, tagIDs: tags, amount: amount, date: .now)
    }

    @Test("Texte insensible à la casse et aux accents, tous les mots requis")
    func text() {
        #expect(TextSearch.matches("cafe", in: ["Café de la Gare"]))
        #expect(TextSearch.matches("GARE café", in: ["Café de la Gare"]))
        #expect(!TextSearch.matches("café métro", in: ["Café de la Gare"]))
        #expect(TextSearch.matches("  ", in: ["x"]))
        #expect(TextSearch.matches("noel", in: ["Cadeaux", "Noël 2026"]))
    }

    @Test("Recherche par montant, avec virgule ou point")
    func amountSearch() {
        #expect(TransactionFilter(text: "12,50").matches(fields()))
        #expect(TransactionFilter(text: "12.5").matches(fields()))
        #expect(!TransactionFilter(text: "13").matches(fields()))
    }

    @Test("Filtre catégorie : le parent inclut ses sous-catégories")
    func category() {
        #expect(TransactionFilter(categoryIDs: [food]).matches(fields()))
        #expect(TransactionFilter(categoryIDs: [groceries, other]).matches(fields()))
        #expect(!TransactionFilter(categoryIDs: [other]).matches(fields()))
        #expect(!TransactionFilter(categoryIDs: [food]).matches(fields(categories: [])))
    }

    @Test("Filtres compte et tag, combinés en ET")
    func accountAndTags() {
        #expect(TransactionFilter(accountIDs: [account]).matches(fields()))
        #expect(!TransactionFilter(accountIDs: [other]).matches(fields()))
        #expect(!TransactionFilter(accountIDs: [account]).matches(TransactionSearchFields(texts: [], categoryIDs: [], accountID: nil, tagIDs: [], amount: 0, date: .now)))
        #expect(TransactionFilter(tagIDs: [trip]).matches(fields(tags: [trip])))
        #expect(!TransactionFilter(accountIDs: [account], tagIDs: [trip]).matches(fields()))
        #expect(TransactionFilter(text: "carrefour", categoryIDs: [food], accountIDs: [account], tagIDs: [trip]).matches(fields(tags: [trip])))
    }

    @Test("Compteur de critères actifs")
    func counters() {
        #expect(TransactionFilter().isEmpty)
        #expect(TransactionFilter(text: "x").activeCriteriaCount == 0)
        #expect(!TransactionFilter(text: "x").isEmpty)
        #expect(TransactionFilter(categoryIDs: [food], tagIDs: [trip]).activeCriteriaCount == 2)
    }
}

@Suite("Regroupement par jour et flux")
struct GroupingTests {
    static let paris: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Europe/Paris")!
        return c
    }()

    static func date(_ d: Int, _ h: Int) -> Date {
        paris.date(from: DateComponents(year: 2026, month: 3, day: d, hour: h))!
    }

    @Test("Jours décroissants, ordre interne préservé, minuit local")
    func grouping() {
        let items = [(Self.date(3, 9), "a"), (Self.date(1, 23), "b"), (Self.date(3, 8), "c"), (Self.date(2, 0), "d")]
        let groups = DayGrouping.group(items, date: { $0.0 }, calendar: Self.paris)
        #expect(groups.map { $0.items.map(\.1) } == [["a", "c"], ["d"], ["b"]])
        #expect(groups[0].day == Self.paris.startOfDay(for: Self.date(3, 12)))
        #expect(DayGrouping.group([(Date, String)](), date: { $0.0 }, calendar: Self.paris).isEmpty)
    }

    @Test("Flux de période : virements et parents de split ignorés, bornes respectées")
    func cashFlow() {
        let period = BudgetPeriod.containing(Self.date(10, 12), startDay: 1, calendar: Self.paris)
        let items = [
            FlowItem(amount: -40, kind: .expense, isSplitParent: true, date: Self.date(5, 12)),
            FlowItem(amount: -25, kind: .expense, date: Self.date(5, 12)),
            FlowItem(amount: -15, kind: .expense, date: Self.date(5, 12)),
            FlowItem(amount: 2000, kind: .income, date: Self.date(1, 0)),
            FlowItem(amount: 10, kind: .refund, date: Self.date(6, 12)),
            FlowItem(amount: -500, kind: .transfer, date: Self.date(7, 12)),
            FlowItem(amount: -99, kind: .expense, date: Self.paris.date(from: DateComponents(year: 2026, month: 4, day: 1))!),
        ]
        let summary = CashFlowSummary.compute(items, in: period)
        #expect(summary.outflow == -40)
        #expect(summary.inflow == 2010)
        #expect(summary.net == 1970)
    }
}

@Suite("Couleurs hexadécimales")
struct HexColorTests {
    @Test("Lecture et écriture aller-retour", arguments: ["#5E7CE2", "#000000", "#FFFFFF", "#3FA34D"])
    func roundTrip(hex: String) {
        #expect(HexColor(hex)?.hexString == hex)
    }

    @Test("Formats acceptés et refusés")
    func formats() {
        #expect(HexColor("5e7ce2")?.hexString == "#5E7CE2")
        #expect(HexColor("#fff")?.hexString == "#FFFFFF")
        #expect(HexColor("#12345") == nil)
        #expect(HexColor("#GGGGGG") == nil)
        #expect(HexColor("") == nil)
        #expect(HexColor(red: 2, green: -1, blue: 0.5).hexString == "#FF0080")
    }
}

@Suite("Décimaux exacts")
struct ExactDecimalTests {
    @Test("Construit depuis le texte, sans erreur binaire")
    func exact() {
        #expect(Decimal.exact("23.40") == Decimal(string: "23.4")!)
        #expect(Decimal.exact("0.1") + Decimal.exact("0.2") == Decimal.exact("0.3"))
        #expect(Decimal.exact("-1234.56").description == "-1234.56")
    }
}
