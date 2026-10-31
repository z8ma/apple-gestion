import Foundation
import PeculeCore
import SwiftData

/// Abonnement détecté (annexe E.7) ou ajouté à la main (M5).
@Model
final class Subscription {
    var id: UUID = UUID()
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now

    var merchantKey: String = ""
    var displayName: String = ""
    var expectedAmount: Decimal = 0
    var frequencyRaw: String = SubscriptionFrequency.monthly.rawValue
    var nextExpectedDate: Date = Date.now
    var category: Category?
    var statusRaw: String = SubscriptionStatus.suggested.rawValue
    var lastAmount: Decimal = 0
    var priceChangeDetected: Bool = false

    init(merchantKey: String, displayName: String, expectedAmount: Decimal, frequency: SubscriptionFrequency, nextExpectedDate: Date) {
        self.merchantKey = merchantKey
        self.displayName = displayName
        self.expectedAmount = expectedAmount
        self.frequencyRaw = frequency.rawValue
        self.nextExpectedDate = nextExpectedDate
        self.lastAmount = expectedAmount
    }

    var frequency: SubscriptionFrequency {
        get { .decoded(frequencyRaw, default: .monthly) }
        set { frequencyRaw = newValue.rawValue }
    }

    var status: SubscriptionStatus {
        get { .decoded(statusRaw, default: .suggested) }
        set { statusRaw = newValue.rawValue }
    }
}
