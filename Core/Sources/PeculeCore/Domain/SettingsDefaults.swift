import Foundation

/// Valeurs par défaut de `UserSettings` (SPEC B.6). Seul endroit où elles sont figées.
public enum SettingsDefaults {
    public static let budgetMode: BudgetMode = .categoryMonthly
    public static let periodStartDay = 1
    public static let currency = "EUR"
    /// 80 % et 100 % (construits en Decimal exact, jamais depuis un Double).
    public static let alertThresholds: [Decimal] = [Decimal(8) / Decimal(10), Decimal(1)]
    public static let subscriptionReminderDays = 3
    public static let lockWithBiometrics = false
    public static let aiCategorizationEnabled = true
    public static let captureNotificationEnabled = true
    public static let natureLabels = ["Essentiel", "Plaisir", "Épargne"]
    public static let monthlyReportEnabled = true
    /// Part d'un compte comptée dans le budget (100 % ; 50 pour un compte joint).
    public static let budgetSharePercent = Decimal(100)
}
