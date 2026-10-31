import Foundation

/// Élément de flux minimal pour les totaux (indépendant de SwiftData).
public struct FlowItem: Sendable {
    public var amount: Decimal
    public var kind: TransactionKind
    /// Un parent de split n'est jamais compté : ses parts le sont.
    public var isSplitParent: Bool
    public var date: Date

    public init(amount: Decimal, kind: TransactionKind, isSplitParent: Bool = false, date: Date) {
        self.amount = amount
        self.kind = kind
        self.isSplitParent = isSplitParent
        self.date = date
    }
}

/// Entrées et sorties brutes d'une période (hors virements). Le budget détaillé
/// (remboursements, exclusions, comptes joints) est calculé en M4.
public struct CashFlowSummary: Equatable, Sendable {
    /// Somme des sorties (négative ou nulle).
    public var outflow: Decimal = 0
    /// Somme des entrées (positive ou nulle).
    public var inflow: Decimal = 0
    public var net: Decimal { inflow + outflow }

    public init(outflow: Decimal = 0, inflow: Decimal = 0) {
        self.outflow = outflow
        self.inflow = inflow
    }

    public static func compute(_ items: [FlowItem], in period: BudgetPeriod) -> CashFlowSummary {
        var summary = CashFlowSummary()
        for item in items where !item.isSplitParent && item.kind != .transfer && period.contains(item.date) {
            if item.amount < 0 { summary.outflow += item.amount } else { summary.inflow += item.amount }
        }
        return summary
    }
}
