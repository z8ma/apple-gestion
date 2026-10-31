import PeculeCore
import SwiftUI

/// Montant formaté dans la devise et la locale de l'utilisateur. Entrées en vert.
struct AmountText: View {
    let amount: Decimal
    let currency: String
    var kind: TransactionKind?

    var body: some View {
        Text(amount, format: .currency(code: currency))
            .monospacedDigit()
            .foregroundStyle(style)
    }

    private var style: Color {
        if kind == .transfer { return .secondary }
        return amount > 0 ? .green : .primary
    }
}

#Preview {
    VStack {
        AmountText(amount: -12.5, currency: "EUR")
        AmountText(amount: 2_450, currency: "EUR", kind: .income)
        AmountText(amount: -300, currency: "EUR", kind: .transfer)
    }
}
