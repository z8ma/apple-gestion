import Foundation

/// Catégorie à créer au premier lancement (annexe E.6).
public struct CategorySeed: Hashable, Sendable {
    /// Identifiant stable, indépendant du nom (renommable) : sert au dédoublonnage CloudKit.
    public let key: String
    public let name: String
    public let symbol: String
    public let colorHex: String
    public let kind: CategoryKind
    public let children: [CategorySeed]

    public init(key: String, name: String, symbol: String, colorHex: String, kind: CategoryKind, children: [CategorySeed] = []) {
        self.key = key
        self.name = name
        self.symbol = symbol
        self.colorHex = colorHex
        self.kind = kind
        self.children = children
    }
}

/// Jeu de catégories par défaut (annexe E.6). Symboles et couleurs : valeurs par défaut éditables.
public enum DefaultCategories {
    public static let all: [CategorySeed] = expenses + incomes + others

    /// Toutes les catégories, parents puis enfants, dans l'ordre d'affichage.
    public static var flattened: [(seed: CategorySeed, parentKey: String?)] {
        all.flatMap { parent in
            [(parent, nil)] + parent.children.map { ($0, parent.key) }
        }
    }

    private static func group(_ key: String, _ name: String, _ symbol: String, _ color: String, _ kind: CategoryKind = .expense, _ children: [(String, String, String)] = []) -> CategorySeed {
        CategorySeed(
            key: key, name: name, symbol: symbol, colorHex: color, kind: kind,
            children: children.map { CategorySeed(key: "\(key).\($0.0)", name: $0.1, symbol: $0.2, colorHex: color, kind: kind) }
        )
    }

    static let expenses: [CategorySeed] = [
        group("expense.housing", "Logement", "house.fill", "#5E7CE2", .expense, [
            ("rent", "Loyer", "key.fill"),
            ("energy", "Énergie", "bolt.fill"),
            ("internet", "Internet & mobile", "wifi"),
            ("insurance", "Assurance habitation", "shield.lefthalf.filled"),
        ]),
        group("expense.food", "Alimentation", "cart.fill", "#3FA34D", .expense, [
            ("groceries", "Courses", "basket.fill"),
            ("restaurants", "Restaurants", "fork.knife"),
            ("delivery", "Livraison", "takeoutbag.and.cup.and.straw.fill"),
            ("cafes", "Cafés", "cup.and.saucer.fill"),
        ]),
        group("expense.transport", "Transports", "car.fill", "#F2994A", .expense, [
            ("fuel", "Carburant", "fuelpump.fill"),
            ("public", "Transports en commun", "tram.fill"),
            ("taxi", "Taxi & VTC", "car.rear.fill"),
            ("maintenance", "Entretien véhicule", "wrench.and.screwdriver.fill"),
            ("parking", "Parking & péage", "parkingsign.circle.fill"),
        ]),
        group("expense.health", "Santé", "cross.case.fill", "#EB5757", .expense, [
            ("doctor", "Médecin", "stethoscope"),
            ("pharmacy", "Pharmacie", "pills.fill"),
            ("insurance", "Mutuelle", "heart.text.square.fill"),
        ]),
        group("expense.leisure", "Loisirs", "gamecontroller.fill", "#9B51E0", .expense, [
            ("outings", "Sorties", "party.popper.fill"),
            ("sport", "Sport", "figure.run"),
            ("culture", "Culture", "theatermasks.fill"),
            ("travel", "Voyages", "airplane"),
        ]),
        group("expense.shopping", "Shopping", "bag.fill", "#E056A0", .expense, [
            ("clothing", "Vêtements", "tshirt.fill"),
            ("tech", "High-tech", "iphone"),
            ("home", "Maison", "sofa.fill"),
        ]),
        group("expense.subscriptions", "Abonnements", "repeat.circle.fill", "#2D9CDB", .expense, [
            ("streaming", "Streaming", "play.tv.fill"),
            ("software", "Logiciels", "square.stack.3d.up.fill"),
            ("press", "Presse", "newspaper.fill"),
        ]),
        group("expense.taxes", "Impôts & taxes", "building.columns.fill", "#828282"),
        group("expense.bankFees", "Frais bancaires", "creditcard.fill", "#4F4F4F"),
        group("expense.gifts", "Cadeaux & dons", "gift.fill", "#F2C94C"),
        group("expense.children", "Enfants", "figure.and.child.holdinghands", "#56CCF2"),
        group("expense.pets", "Animaux", "pawprint.fill", "#A0785A"),
        group("expense.misc", "Divers", "ellipsis.circle.fill", "#BDBDBD"),
    ]

    static let incomes: [CategorySeed] = [
        group("income.salary", "Salaire", "banknote.fill", "#27AE60", .income),
        group("income.refunds", "Remboursements", "arrow.uturn.backward.circle.fill", "#6FCF97", .income),
        group("income.benefits", "Aides", "hand.raised.fill", "#219653", .income),
        group("income.savingsIncome", "Revenus d'épargne", "chart.line.uptrend.xyaxis", "#1E8449", .income),
        group("income.other", "Autres revenus", "plus.circle.fill", "#58D68D", .income),
    ]

    static let others: [CategorySeed] = [
        group("transfer.internal", "Virements internes", "arrow.left.arrow.right", "#7F8C8D", .transfer),
        group("saving.savings", "Épargne", "archivebox.fill", "#16A085", .saving),
    ]
}
