import Foundation
import Testing
@testable import PeculeCore

@Suite("Catégories par défaut (E.6)")
struct DefaultCategoriesTests {
    @Test("Noms des catégories de dépenses et de leurs sous-catégories conformes à E.6")
    func expenseNames() {
        let tree = DefaultCategories.all.filter { $0.kind == .expense }.map { ($0.name, $0.children.map(\.name)) }
        #expect(tree.map(\.0) == [
            "Logement", "Alimentation", "Transports", "Santé", "Loisirs", "Shopping", "Abonnements",
            "Impôts & taxes", "Frais bancaires", "Cadeaux & dons", "Enfants", "Animaux", "Divers",
        ])
        let children = Dictionary(uniqueKeysWithValues: tree)
        #expect(children["Logement"] == ["Loyer", "Énergie", "Internet & mobile", "Assurance habitation"])
        #expect(children["Alimentation"] == ["Courses", "Restaurants", "Livraison", "Cafés"])
        #expect(children["Transports"] == ["Carburant", "Transports en commun", "Taxi & VTC", "Entretien véhicule", "Parking & péage"])
        #expect(children["Santé"] == ["Médecin", "Pharmacie", "Mutuelle"])
        #expect(children["Loisirs"] == ["Sorties", "Sport", "Culture", "Voyages"])
        #expect(children["Shopping"] == ["Vêtements", "High-tech", "Maison"])
        #expect(children["Abonnements"] == ["Streaming", "Logiciels", "Presse"])
        #expect(children["Divers"] == [])
    }

    @Test("Revenus et autres catégories conformes à E.6")
    func incomeAndOthers() {
        #expect(DefaultCategories.all.filter { $0.kind == .income }.map(\.name) == [
            "Salaire", "Remboursements", "Aides", "Revenus d'épargne", "Autres revenus",
        ])
        #expect(DefaultCategories.all.filter { $0.kind == .transfer }.map(\.name) == ["Virements internes"])
        #expect(DefaultCategories.all.filter { $0.kind == .saving }.map(\.name) == ["Épargne"])
    }

    @Test("Clés uniques, un seul niveau, enfants du même type que le parent")
    func structure() {
        let flat = DefaultCategories.flattened
        #expect(flat.count == 46) // 20 catégories + 26 sous-catégories
        #expect(Set(flat.map(\.seed.key)).count == flat.count)
        for parent in DefaultCategories.all {
            for child in parent.children {
                #expect(child.children.isEmpty)
                #expect(child.kind == parent.kind)
                #expect(child.key.hasPrefix(parent.key + "."))
            }
        }
        #expect(flat.filter { $0.parentKey == nil }.count == DefaultCategories.all.count)
    }

    @Test("Couleurs hexadécimales valides et symboles renseignés")
    func appearance() {
        for (seed, _) in DefaultCategories.flattened {
            #expect(seed.colorHex.wholeMatch(of: /#[0-9A-F]{6}/) != nil, "\(seed.name)")
            #expect(!seed.symbol.isEmpty)
        }
    }
}

@Suite("Valeurs par défaut des réglages")
struct SettingsDefaultsTests {
    @Test("Seuils d'alerte exacts (pas d'arrondi de Double)")
    func thresholds() {
        #expect(SettingsDefaults.alertThresholds == [Decimal(string: "0.8")!, Decimal(1)])
    }

    @Test("Valeurs de la spec B.6")
    func values() {
        #expect(SettingsDefaults.periodStartDay == 1)
        #expect(SettingsDefaults.currency == "EUR")
        #expect(SettingsDefaults.subscriptionReminderDays == 3)
        #expect(SettingsDefaults.natureLabels == ["Essentiel", "Plaisir", "Épargne"])
        #expect(SettingsDefaults.budgetMode == .categoryMonthly)
        #expect(BudgetPeriod.allowedStartDays.contains(SettingsDefaults.periodStartDay))
    }

    @Test("Décodage tolérant des énumérations persistées")
    func decoding() {
        #expect(TransactionKind.decoded("refund", default: .expense) == .refund)
        #expect(TransactionKind.decoded("inconnu", default: .expense) == .expense)
        #expect(TransactionSource.decoded(nil, default: .manual) == .manual)
        #expect(TransactionSource.decoded("import", default: .manual) == .import)
    }
}

@Suite("Dédoublonnage CloudKit")
struct DeduplicationTests {
    struct Item: Equatable {
        let key: String?
        let createdAt: Date
        let id: UUID
    }

    static func uuid(_ n: Int) -> UUID { UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", n))! }

    @Test("Le plus ancien est conservé, les autres sont des doublons")
    func keepsOldest() {
        let a = Item(key: "k", createdAt: Date(timeIntervalSince1970: 20), id: Self.uuid(1))
        let b = Item(key: "k", createdAt: Date(timeIntervalSince1970: 10), id: Self.uuid(2))
        let c = Item(key: "k", createdAt: Date(timeIntervalSince1970: 30), id: Self.uuid(3))
        let groups = Deduplication.groups([a, b, c], key: \.key, createdAt: \.createdAt, id: \.id)
        #expect(groups.count == 1)
        #expect(groups[0].keeper == b)
        #expect(groups[0].duplicates == [a, c])
    }

    @Test("Égalité de date : choix déterministe par identifiant")
    func tieBreak() {
        let date = Date(timeIntervalSince1970: 0)
        let x = Item(key: "k", createdAt: date, id: Self.uuid(9))
        let y = Item(key: "k", createdAt: date, id: Self.uuid(4))
        #expect(Deduplication.groups([x, y], key: \.key, createdAt: \.createdAt, id: \.id)[0].keeper == y)
        #expect(Deduplication.groups([y, x], key: \.key, createdAt: \.createdAt, id: \.id)[0].keeper == y)
    }

    @Test("Sans doublon ou sans clé : aucun groupe")
    func noDuplicates() {
        let items = [
            Item(key: "a", createdAt: .now, id: Self.uuid(1)),
            Item(key: "b", createdAt: .now, id: Self.uuid(2)),
            Item(key: nil, createdAt: .now, id: Self.uuid(3)),
            Item(key: nil, createdAt: .now, id: Self.uuid(4)),
        ]
        #expect(Deduplication.groups(items, key: \.key, createdAt: \.createdAt, id: \.id).isEmpty)
    }
}
