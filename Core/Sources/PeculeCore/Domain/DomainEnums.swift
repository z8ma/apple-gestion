import Foundation

// Énumérations du domaine (SPEC B.6). Persistées sous forme de `rawValue` (String)
// dans SwiftData, pour rester robustes face aux évolutions du schéma CloudKit (ADR-008).

public enum BudgetMode: String, Codable, Sendable, CaseIterable {
    case categoryMonthly
    case envelopes
}

public enum AccountType: String, Codable, Sendable, CaseIterable {
    case checking, savings, card, investment, lifeInsurance, crypto, loan, realEstate, otherAsset

    /// Un prêt est une dette : il réduit le patrimoine net.
    public var isLiability: Bool { self == .loan }
}

public enum ConnectionStatus: String, Codable, Sendable, CaseIterable {
    case active, expiringSoon, expired, error
}

public enum TransactionKind: String, Codable, Sendable, CaseIterable {
    case expense, income, transfer, refund
}

public enum TransactionSource: String, Codable, Sendable, CaseIterable {
    case manual, applePay, bank, `import`
}

public enum TransactionStatus: String, Codable, Sendable, CaseIterable {
    /// Capture non rapprochée.
    case pending
    case posted
    case reconciled
}

public enum CategorizationOrigin: String, Codable, Sendable, CaseIterable {
    case user, rule, ai, none
}

public enum CategoryKind: String, Codable, Sendable, CaseIterable {
    case expense, income, transfer, saving
}

public enum LabelMatchKind: String, Codable, Sendable, CaseIterable {
    case contains, equals, startsWith, regex
}

public enum SubscriptionFrequency: String, Codable, Sendable, CaseIterable {
    case weekly, monthly, quarterly, yearly
}

public enum SubscriptionStatus: String, Codable, Sendable, CaseIterable {
    case suggested, confirmed, ignored, cancelled
}

extension RawRepresentable where RawValue == String {
    /// Décodage tolérant d'une valeur persistée : valeur inconnue → `fallback`.
    public static func decoded(_ raw: String?, default fallback: Self) -> Self {
        raw.flatMap(Self.init(rawValue:)) ?? fallback
    }
}
