import Foundation
import PeculeCore
import SwiftData

/// Réglages de l'utilisateur (singleton logique : voir `SettingsStore`).
@Model
final class UserSettings {
    var id: UUID = UUID()
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now

    var budgetModeRaw: String = SettingsDefaults.budgetMode.rawValue
    /// 1–28 (voir `BudgetPeriod.allowedStartDays`).
    var periodStartDay: Int = SettingsDefaults.periodStartDay
    var defaultCurrency: String = SettingsDefaults.currency
    var alertThresholds: [Decimal] = SettingsDefaults.alertThresholds
    var subscriptionReminderDays: Int = SettingsDefaults.subscriptionReminderDays
    var lockWithBiometrics: Bool = SettingsDefaults.lockWithBiometrics
    var aiCategorizationEnabled: Bool = SettingsDefaults.aiCategorizationEnabled
    var captureNotificationEnabled: Bool = SettingsDefaults.captureNotificationEnabled
    var natureLabels: [String] = SettingsDefaults.natureLabels
    var monthlyReportEnabled: Bool = SettingsDefaults.monthlyReportEnabled

    init() {}

    var budgetMode: BudgetMode {
        get { .decoded(budgetModeRaw, default: SettingsDefaults.budgetMode) }
        set { budgetModeRaw = newValue.rawValue }
    }

    /// Période budgétaire contenant `date`, dans le fuseau de l'utilisateur.
    func period(containing date: Date = .now, calendar: Calendar = .current) -> BudgetPeriod {
        BudgetPeriod.containing(date, startDay: periodStartDay, calendar: calendar)
    }
}
