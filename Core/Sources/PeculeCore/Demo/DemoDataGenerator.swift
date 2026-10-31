import Foundation

/// Générateur pseudo-aléatoire déterministe (SplitMix64) : même graine, mêmes données.
public struct SeededGenerator: RandomNumberGenerator, Sendable {
    private var state: UInt64

    public init(seed: UInt64) { state = seed }

    public mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

public struct DemoAccount: Equatable, Sendable {
    public let key: String
    public let name: String
    public let institution: String
    public let type: AccountType
    public let colorHex: String
    public let includeInBudget: Bool
    public let budgetSharePercent: Decimal
    public let openingBalance: Decimal
}

public struct DemoTransaction: Equatable, Sendable {
    public let id: Int
    public let accountKey: String
    public let date: Date
    public let label: String
    public let amount: Decimal
    public let kind: TransactionKind
    /// `nil` : transaction « à catégoriser ».
    public let categoryKey: String?
    public let tags: [String]
    public let nature: String?
    /// Identifiant de la dépense remboursée.
    public let refundOf: Int?
}

public struct DemoDataset: Equatable, Sendable {
    public let accounts: [DemoAccount]
    public let tags: [(name: String, colorHex: String)]
    public let transactions: [DemoTransaction]
    public let start: Date
    public let end: Date

    public func closingBalance(of accountKey: String) -> Decimal {
        let opening = accounts.first { $0.key == accountKey }?.openingBalance ?? 0
        return transactions.filter { $0.accountKey == accountKey }.reduce(opening) { $0 + $1.amount }
    }

    public static func == (lhs: DemoDataset, rhs: DemoDataset) -> Bool {
        lhs.accounts == rhs.accounts && lhs.transactions == rhs.transactions
            && lhs.tags.map(\.name) == rhs.tags.map(\.name) && lhs.start == rhs.start && lhs.end == rhs.end
    }
}

/// Données de démo réalistes (le simulateur ne peut pas déclencher Apple Pay).
public enum DemoDataGenerator {
    public static let tripTag = "Vacances Italie"

    public static func make(months: Int = 6, endingAt end: Date, calendar: Calendar, seed: UInt64 = 42) -> DemoDataset {
        var builder = Builder(rng: SeededGenerator(seed: seed), calendar: calendar)
        let start = calendar.startOfDay(for: calendar.date(byAdding: .month, value: -max(months, 1), to: end) ?? end)
        var day = start
        var monthIndex = 0
        var lastMonth = calendar.component(.month, from: start)
        while day <= end {
            let month = calendar.component(.month, from: day)
            if month != lastMonth { monthIndex += 1; lastMonth = month }
            builder.generate(day: day, monthIndex: monthIndex, months: months, end: end)
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        builder.addUncategorized(start: start, end: end)
        let sorted = builder.transactions.sorted { $0.date < $1.date }
        return DemoDataset(accounts: accounts, tags: [(tripTag, "#F2994A")], transactions: sorted, start: start, end: end)
    }

    static let accounts: [DemoAccount] = [
        DemoAccount(key: "checking", name: "Compte courant", institution: "Banque Démo", type: .checking,
                    colorHex: "#5E7CE2", includeInBudget: true, budgetSharePercent: 100, openingBalance: .exact("1200")),
        DemoAccount(key: "joint", name: "Compte joint", institution: "Banque Démo", type: .checking,
                    colorHex: "#E056A0", includeInBudget: true, budgetSharePercent: 50, openingBalance: .exact("600")),
        DemoAccount(key: "savings", name: "Livret A", institution: "Banque Démo", type: .savings,
                    colorHex: "#16A085", includeInBudget: false, budgetSharePercent: 100, openingBalance: .exact("4000")),
    ]

    private struct Builder {
        var rng: SeededGenerator
        let calendar: Calendar
        var transactions: [DemoTransaction] = []
        var nextID = 1

        mutating func generate(day: Date, monthIndex: Int, months: Int, end: Date) {
            let dom = calendar.component(.day, from: day)
            let weekday = calendar.component(.weekday, from: day) // 1 = dimanche
            let isWeekday = (2...6).contains(weekday)

            // Charges et revenus récurrents
            switch dom {
            case 1: add(day, "Loyer Agence Martin", fixed("-890"), "expense.housing.rent", nature: "Essentiel", end: end)
            case 2: add(day, "Navigo Mois", fixed("-86.40"), "expense.transport.public", nature: "Essentiel", end: end)
            case 3: add(day, "Assurance Habitation", fixed("-18.50"), "expense.housing.insurance", nature: "Essentiel", end: end)
            case 5:
                add(day, "Free Box", fixed("-29.99"), "expense.housing.internet", nature: "Essentiel", end: end)
                add(day, "Sosh Mobile", fixed("-12.99"), "expense.housing.internet", nature: "Essentiel", end: end)
            case 6: add(day, "Cotisation carte", fixed("-2.50"), "expense.bankFees", nature: "Essentiel", end: end)
            case 8: add(day, "EDF Électricité", cents(-8_200, -6_400), "expense.housing.energy", nature: "Essentiel", end: end)
            case 10: add(day, "Netflix", fixed("-15.99"), "expense.subscriptions.streaming", nature: "Plaisir", end: end)
            case 12: add(day, "Spotify", fixed("-11.99"), "expense.subscriptions.streaming", nature: "Plaisir", end: end)
            case 15: add(day, "Basic-Fit", fixed("-29.99"), "expense.leisure.sport", nature: "Plaisir", end: end)
            case 20: add(day, "Mutuelle Santé", fixed("-42.30"), "expense.health.insurance", nature: "Essentiel", end: end)
            case 27: add(day, "Salaire ACME SAS", cents(245_000, 252_000), "income.salary", kind: .income, end: end)
            case 28:
                add(day, "Virement vers Livret A", fixed("-200"), "transfer.internal", kind: .transfer, end: end)
                add(day, "Virement depuis Compte courant", fixed("200"), "transfer.internal", kind: .transfer, account: "savings", end: end)
            default: break
            }
            if dom == 9 || dom == 23 {
                add(day, "TotalEnergies", cents(-7_500, -4_500), "expense.transport.fuel", nature: "Essentiel", end: end)
            }

            // Dépenses variables
            if chance(0.3) {
                add(day, pick(["Carrefour City", "Monoprix", "Lidl", "Picard"]), cents(-9_500, -800), "expense.food.groceries", nature: "Essentiel", end: end)
            }
            if weekday == 7 {
                add(day, "Biocoop", cents(-12_000, -4_000), "expense.food.groceries", nature: "Essentiel", account: "joint", end: end)
            }
            if isWeekday && chance(0.35) {
                add(day, pick(["Café de la Gare", "Starbucks", "Boulangerie Paul"]), cents(-580, -220), "expense.food.cafes", nature: "Plaisir", end: end)
            }
            if (weekday == 6 || weekday == 7) && chance(0.5) {
                add(day, pick(["Le Petit Bistro", "Sushi Shop", "Big Mamma"]), cents(-6_500, -1_800), "expense.food.restaurants", nature: "Plaisir", end: end)
            }
            if chance(0.06) { add(day, pick(["Uber Eats", "Deliveroo"]), cents(-3_800, -1_500), "expense.food.delivery", nature: "Plaisir", end: end) }
            if chance(0.04) { add(day, "Uber", cents(-2_800, -900), "expense.transport.taxi", nature: "Plaisir", end: end) }
            if chance(0.05) { add(day, "Pharmacie du Centre", cents(-3_500, -400), "expense.health.pharmacy", nature: "Essentiel", end: end) }
            if chance(0.05) {
                let (label, key) = pick([("Zara", "expense.shopping.clothing"), ("Fnac", "expense.shopping.tech"),
                                         ("IKEA", "expense.shopping.home"), ("Decathlon", "expense.leisure.sport")])
                add(day, label, cents(-14_000, -2_000), key, nature: "Plaisir", end: end)
            }

            // Médecin remboursé (deux fois sur la période)
            if dom == 14 && (monthIndex == 1 || monthIndex == 4) {
                if let visit = add(day, "Dr Martin", fixed("-30"), "expense.health.doctor", nature: "Essentiel", end: end),
                   let later = calendar.date(byAdding: .day, value: 5, to: day) {
                    add(later, "CPAM Remboursement", fixed("21"), "expense.health.doctor", kind: .refund, refundOf: visit, end: end)
                }
            }

            // Voyage tagué (trois mois avant la fin)
            if monthIndex == max(months - 3, 0) && (10...16).contains(dom) {
                let trip = [DemoDataGenerator.tripTag]
                if dom == 10 {
                    add(day, "Trenitalia", fixed("-89"), "expense.leisure.travel", nature: "Plaisir", tags: trip, end: end)
                    add(day, "Hotel Roma Centro", fixed("-420"), "expense.leisure.travel", nature: "Plaisir", tags: trip, end: end)
                }
                if dom == 12 { add(day, "Musei Vaticani", fixed("-27"), "expense.leisure.culture", nature: "Plaisir", tags: trip, end: end) }
                add(day, "Trattoria da Enzo", cents(-6_000, -2_500), "expense.food.restaurants", nature: "Plaisir", tags: trip, end: end)
            }

            if monthIndex == max(months - 2, 0) && dom == 18 {
                add(day, "Cadeau anniversaire", fixed("-45"), "expense.gifts", nature: "Plaisir", end: end)
            }
        }

        mutating func addUncategorized(start: Date, end: Date) {
            let span = max(end.timeIntervalSince(start), 1)
            for index in 0..<3 {
                let offset = span * (Double(index) + 0.5) / 3
                add(start.addingTimeInterval(offset), "PAIEMENT CB 4521 MARKET \(index + 1)", cents(-4_000, -500), nil, end: end)
            }
        }

        @discardableResult
        mutating func add(_ day: Date, _ label: String, _ amount: Decimal, _ categoryKey: String?, kind: TransactionKind = .expense,
                          nature: String? = nil, tags: [String] = [], account: String = "checking", refundOf: Int? = nil, end: Date) -> Int? {
            let hour = Int.random(in: 8...21, using: &rng)
            let minute = Int.random(in: 0...59, using: &rng)
            let date = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
            guard date <= end else { return nil }
            let id = nextID
            nextID += 1
            transactions.append(DemoTransaction(id: id, accountKey: account, date: date, label: label, amount: amount, kind: kind,
                                                categoryKey: categoryKey, tags: tags, nature: nature, refundOf: refundOf))
            return id
        }

        mutating func chance(_ probability: Double) -> Bool { Double.random(in: 0..<1, using: &rng) < probability }
        mutating func pick<T>(_ items: [T]) -> T { items[Int.random(in: 0..<items.count, using: &rng)] }
        /// Montant aléatoire en centimes entre `low` et `high` (inclus).
        mutating func cents(_ low: Int, _ high: Int) -> Decimal { Decimal(Int.random(in: low...high, using: &rng)) / 100 }
        func fixed(_ text: String) -> Decimal { .exact(text) }
    }
}
