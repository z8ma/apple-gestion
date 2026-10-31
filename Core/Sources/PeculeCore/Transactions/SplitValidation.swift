import Foundation

/// Division d'une transaction en parts (SPEC B.6) : la somme des parts doit être
/// exactement égale au montant du parent.
public enum SplitValidation {
    public enum Issue: Error, Equatable, Sendable {
        /// Au moins deux parts.
        case notEnoughParts
        /// Une part est nulle.
        case zeroPart(index: Int)
        /// Une part n'a pas le signe du parent (ex. part positive d'une dépense).
        case signMismatch(index: Int)
        /// Somme des parts ≠ montant ; `remaining` = montant − somme.
        case sumMismatch(remaining: Decimal)
    }

    /// Montant restant à répartir (montant − somme des parts).
    public static func remaining(total: Decimal, parts: [Decimal]) -> Decimal {
        total - parts.reduce(0, +)
    }

    /// Problèmes empêchant l'enregistrement ; vide si la répartition est valide.
    public static func issues(total: Decimal, parts: [Decimal]) -> [Issue] {
        var issues: [Issue] = []
        if parts.count < 2 { issues.append(.notEnoughParts) }
        for (index, part) in parts.enumerated() {
            if part == 0 {
                issues.append(.zeroPart(index: index))
            } else if (part < 0) != (total < 0) {
                issues.append(.signMismatch(index: index))
            }
        }
        let rest = remaining(total: total, parts: parts)
        if rest != 0 { issues.append(.sumMismatch(remaining: rest)) }
        return issues
    }

    public static func isValid(total: Decimal, parts: [Decimal]) -> Bool {
        issues(total: total, parts: parts).isEmpty
    }

    /// Répartition en `count` parts égales au centime ; les centimes restants vont
    /// aux premières parts. La somme vaut toujours exactement `total`.
    public static func evenParts(total: Decimal, count: Int, scale: Int = 2) -> [Decimal] {
        guard count > 0 else { return [] }
        var unit = Decimal(1)
        for _ in 0..<scale { unit /= 10 }
        let sign: Decimal = total < 0 ? -1 : 1
        let magnitude = total.magnitude
        let units = NSDecimalNumber(decimal: magnitude / unit).int64Value
        let base = units / Int64(count)
        let extra = Int(units % Int64(count))
        return (0..<count).map { index in
            sign * Decimal(base + (index < extra ? 1 : 0)) * unit
        }
    }
}

/// Lien « remboursement de » entre deux transactions.
public enum RefundValidation {
    public enum Issue: Error, Equatable, Sendable {
        case sameTransaction
        /// Le remboursement doit être une entrée d'argent.
        case refundNotPositive
        /// La transaction remboursée doit être une dépense.
        case originalNotExpense
        case currencyMismatch
    }

    public struct Side: Sendable {
        public let id: UUID
        public let amount: Decimal
        public let currency: String

        public init(id: UUID, amount: Decimal, currency: String) {
            self.id = id
            self.amount = amount
            self.currency = currency
        }
    }

    public static func validate(refund: Side, original: Side) -> Issue? {
        if refund.id == original.id { return .sameTransaction }
        if refund.amount <= 0 { return .refundNotPositive }
        if original.amount >= 0 { return .originalNotExpense }
        if refund.currency != original.currency { return .currencyMismatch }
        return nil
    }

    /// Avertissement non bloquant : remboursement supérieur à la dépense.
    public static func exceedsOriginal(refund: Side, original: Side) -> Bool {
        refund.amount > original.amount.magnitude
    }
}
