import Foundation

/// Convention de signe (ADR-006) : sortie d'argent < 0, entrée > 0.
public enum SignedAmount {
    /// Montant signé à partir d'une valeur saisie (le signe saisi est ignoré).
    /// - Parameter outgoing: sens d'un virement (`.transfer` uniquement) ; ignoré sinon.
    public static func make(magnitude: Decimal, kind: TransactionKind, outgoing: Bool = true) -> Decimal {
        let positive = magnitude.magnitude
        switch kind {
        case .expense: return -positive
        case .income, .refund: return positive
        case .transfer: return outgoing ? -positive : positive
        }
    }

    /// Arrondi au centime (ou à `scale` décimales), au plus proche, demi vers le haut.
    public static func rounded(_ value: Decimal, scale: Int = 2) -> Decimal {
        var input = value
        var result = Decimal()
        NSDecimalRound(&result, &input, scale, .plain)
        return result
    }
}

extension CategoryKind {
    /// Types de catégorie proposés pour un type d'opération.
    /// Un remboursement se range dans une catégorie de dépense, qu'il vient réduire (M4).
    public static func allowed(for kind: TransactionKind) -> [CategoryKind] {
        switch kind {
        case .expense: [.expense, .saving]
        case .refund: [.expense]
        case .income: [.income]
        case .transfer: [.transfer, .saving]
        }
    }
}

extension Decimal {
    /// Décimal exact depuis un texte au format « 1234.56 » (jamais via un Double).
    /// Réservé aux constantes du code : plante si le texte est invalide.
    public static func exact(_ text: String) -> Decimal {
        guard let value = Decimal(string: text, locale: Locale(identifier: "en_US_POSIX")) else {
            preconditionFailure("Décimal invalide : \(text)")
        }
        return value
    }
}
