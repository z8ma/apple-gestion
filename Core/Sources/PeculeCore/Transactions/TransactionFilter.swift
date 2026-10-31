import Foundation

/// Champs d'une transaction utiles au filtrage, extraits du modèle persistant.
public struct TransactionSearchFields: Sendable {
    public var texts: [String]
    /// Catégories de la transaction et leurs parents (et celles des parts d'un split).
    public var categoryIDs: Set<UUID>
    public var accountID: UUID?
    public var tagIDs: Set<UUID>
    public var amount: Decimal
    public var date: Date

    public init(texts: [String], categoryIDs: Set<UUID>, accountID: UUID?, tagIDs: Set<UUID>, amount: Decimal, date: Date) {
        self.texts = texts
        self.categoryIDs = categoryIDs
        self.accountID = accountID
        self.tagIDs = tagIDs
        self.amount = amount
        self.date = date
    }
}

/// Filtre de la liste des transactions. Critères vides = pas de contrainte.
/// Entre critères : ET. À l'intérieur d'un critère (plusieurs catégories…) : OU.
public struct TransactionFilter: Equatable, Sendable {
    public var text: String = ""
    public var categoryIDs: Set<UUID> = []
    public var accountIDs: Set<UUID> = []
    public var tagIDs: Set<UUID> = []

    public init(text: String = "", categoryIDs: Set<UUID> = [], accountIDs: Set<UUID> = [], tagIDs: Set<UUID> = []) {
        self.text = text
        self.categoryIDs = categoryIDs
        self.accountIDs = accountIDs
        self.tagIDs = tagIDs
    }

    /// Nombre de critères actifs hors texte (badge du bouton Filtres).
    public var activeCriteriaCount: Int {
        [categoryIDs.isEmpty, accountIDs.isEmpty, tagIDs.isEmpty].filter { !$0 }.count
    }

    public var isEmpty: Bool { activeCriteriaCount == 0 && TextSearch.normalize(text).isEmpty }

    public func matches(_ fields: TransactionSearchFields) -> Bool {
        if !categoryIDs.isEmpty && categoryIDs.isDisjoint(with: fields.categoryIDs) { return false }
        if !accountIDs.isEmpty {
            guard let account = fields.accountID, accountIDs.contains(account) else { return false }
        }
        if !tagIDs.isEmpty && tagIDs.isDisjoint(with: fields.tagIDs) { return false }
        return TextSearch.matches(text, in: fields.texts + [Self.searchable(fields.amount)])
    }

    /// Montant cherchable tel qu'on le tape : « 12,5 » ou « 12.50 » trouvent -12,50.
    static func searchable(_ amount: Decimal) -> String {
        let value = SignedAmount.rounded(amount.magnitude)
        let plain = "\(value)"
        let twoDigits = String(format: "%.2f", NSDecimalNumber(decimal: value).doubleValue)
        return [plain, twoDigits, plain.replacingOccurrences(of: ".", with: ","), twoDigits.replacingOccurrences(of: ".", with: ",")]
            .joined(separator: " ")
    }
}
