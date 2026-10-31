import Foundation

/// Période budgétaire (annexe E.8).
///
/// Intervalle semi-ouvert `[start ; end[` : `start` est le `startDay` le plus récent
/// inférieur ou égal à la date de référence (à minuit, fuseau du calendrier),
/// `end` est le même jour du mois suivant.
public struct BudgetPeriod: Hashable, Sendable, Codable {
    /// Bornes autorisées du jour de début : 1–28, pour exister dans tous les mois.
    public static let allowedStartDays: ClosedRange<Int> = 1...28

    public let start: Date
    /// Borne exclue.
    public let end: Date
    public let startDay: Int

    /// Ramène un jour de début quelconque dans 1–28.
    public static func clampedStartDay(_ day: Int) -> Int {
        min(max(day, allowedStartDays.lowerBound), allowedStartDays.upperBound)
    }

    /// Période contenant `date`, pour un `startDay` donné, dans le fuseau de `calendar`.
    public static func containing(_ date: Date, startDay: Int, calendar: Calendar) -> BudgetPeriod {
        let day = clampedStartDay(startDay)
        let parts = calendar.dateComponents([.year, .month], from: date)
        guard let year = parts.year, let month = parts.month else {
            preconditionFailure("Calendrier sans année ni mois")
        }
        var start = startOfDay(year: year, month: month, day: day, calendar: calendar)
        if start > date {
            start = adding(months: -1, to: start, day: day, calendar: calendar)
        }
        let end = adding(months: 1, to: start, day: day, calendar: calendar)
        return BudgetPeriod(start: start, end: end, startDay: day)
    }

    public func contains(_ date: Date) -> Bool {
        date >= start && date < end
    }

    public func next(calendar: Calendar) -> BudgetPeriod {
        BudgetPeriod(
            start: end,
            end: Self.adding(months: 1, to: end, day: startDay, calendar: calendar),
            startDay: startDay
        )
    }

    public func previous(calendar: Calendar) -> BudgetPeriod {
        BudgetPeriod(
            start: Self.adding(months: -1, to: start, day: startDay, calendar: calendar),
            end: start,
            startDay: startDay
        )
    }

    /// Les `count` périodes qui précèdent celle-ci, de la plus récente à la plus ancienne.
    public func preceding(_ count: Int, calendar: Calendar) -> [BudgetPeriod] {
        var result: [BudgetPeriod] = []
        var current = self
        for _ in 0..<max(count, 0) {
            current = current.previous(calendar: calendar)
            result.append(current)
        }
        return result
    }

    // MARK: - Privé

    /// Minuit du jour demandé. Passe par midi pour rester correct dans les fuseaux
    /// où minuit n'existe pas certains jours (changement d'heure à minuit).
    private static func startOfDay(year: Int, month: Int, day: Int, calendar: Calendar) -> Date {
        let noon = DateComponents(year: year, month: month, day: day, hour: 12)
        guard let date = calendar.date(from: noon) else {
            preconditionFailure("Date invalide \(year)-\(month)-\(day)")
        }
        return calendar.startOfDay(for: date)
    }

    private static func adding(months: Int, to date: Date, day: Int, calendar: Calendar) -> Date {
        let parts = calendar.dateComponents([.year, .month], from: date)
        guard let year = parts.year, let month = parts.month else {
            preconditionFailure("Calendrier sans année ni mois")
        }
        // Normalisation du mois (ex. mois 13 → janvier suivant) faite par le calendrier.
        return startOfDay(year: year, month: month + months, day: day, calendar: calendar)
    }
}
