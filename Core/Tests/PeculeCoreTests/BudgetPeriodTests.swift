import Foundation
import Testing
@testable import PeculeCore

@Suite("Calcul de période (E.8)")
struct BudgetPeriodTests {
    static let paris: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Paris")!
        return calendar
    }()

    /// Date dans le fuseau du calendrier.
    static func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 0, _ min: Int = 0, calendar: Calendar = paris) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
    }

    func period(_ date: Date, _ startDay: Int, calendar: Calendar = paris) -> BudgetPeriod {
        BudgetPeriod.containing(date, startDay: startDay, calendar: calendar)
    }

    @Test("Jour de début 1 : mois civil")
    func civilMonth() {
        let p = period(Self.date(2026, 3, 15, 10), 1)
        #expect(p.start == Self.date(2026, 3, 1))
        #expect(p.end == Self.date(2026, 4, 1))
    }

    @Test("Date après le jour de début : la période commence ce mois-ci")
    func afterStartDay() {
        let p = period(Self.date(2026, 1, 31, 12), 27)
        #expect(p.start == Self.date(2026, 1, 27))
        #expect(p.end == Self.date(2026, 2, 27))
    }

    @Test("Date avant le jour de début : la période a commencé le mois précédent")
    func beforeStartDay() {
        let p = period(Self.date(2026, 3, 5), 27)
        #expect(p.start == Self.date(2026, 2, 27))
        #expect(p.end == Self.date(2026, 3, 27))
    }

    @Test("Changement d'année")
    func yearBoundary() {
        let p = period(Self.date(2026, 1, 3), 27)
        #expect(p.start == Self.date(2025, 12, 27))
        #expect(p.end == Self.date(2026, 1, 27))
        let december = period(Self.date(2025, 12, 31, 23, 59), 1)
        #expect(december.end == Self.date(2026, 1, 1))
    }

    @Test("Février d'une année non bissextile, jour 28")
    func februaryCommonYear() {
        let p = period(Self.date(2026, 2, 28, 8), 28)
        #expect(p.start == Self.date(2026, 2, 28))
        #expect(p.end == Self.date(2026, 3, 28))
        let before = period(Self.date(2026, 2, 27, 23, 59), 28)
        #expect(before.start == Self.date(2026, 1, 28))
        #expect(before.end == Self.date(2026, 2, 28))
    }

    @Test("Année bissextile : le 29 février appartient à la période du 28")
    func leapYear() {
        let p = period(Self.date(2024, 2, 29, 12), 28)
        #expect(p.start == Self.date(2024, 2, 28))
        #expect(p.end == Self.date(2024, 3, 28))
        let civil = period(Self.date(2024, 2, 29), 1)
        #expect(civil.start == Self.date(2024, 2, 1))
        #expect(civil.end == Self.date(2024, 3, 1))
    }

    @Test("Fin de mois : 31 janvier et 30 avril")
    func endOfMonth() {
        #expect(period(Self.date(2026, 1, 31, 23, 59), 1).end == Self.date(2026, 2, 1))
        let april = period(Self.date(2026, 4, 30, 23), 15)
        #expect(april.start == Self.date(2026, 4, 15))
        #expect(april.end == Self.date(2026, 5, 15))
    }

    @Test("Bornes : le début est inclus, la fin est exclue")
    func bounds() {
        let start = Self.date(2026, 3, 27)
        let p = period(start, 27)
        #expect(p.start == start)
        #expect(p.contains(start))
        #expect(!p.contains(p.end))
        #expect(p.contains(p.end.addingTimeInterval(-1)))
        #expect(period(start.addingTimeInterval(-1), 27).end == start)
    }

    @Test("Jour de début hors bornes ramené dans 1–28", arguments: [
        (-3, 1), (0, 1), (1, 1), (28, 28), (29, 28), (31, 28), (100, 28),
    ])
    func clamping(input: Int, expected: Int) {
        #expect(BudgetPeriod.clampedStartDay(input) == expected)
        #expect(period(Self.date(2026, 6, 10), input).startDay == expected)
    }

    @Test("Le fuseau horaire de l'utilisateur fait foi")
    func timeZone() {
        // 26 mars 23:30 UTC = 27 mars 00:30 à Paris (UTC+1 avant le changement d'heure).
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC")!
        let instant = Self.date(2026, 3, 26, 23, 30, calendar: utc)
        #expect(period(instant, 27).start == Self.date(2026, 3, 27))
        #expect(period(instant, 27, calendar: utc).start == Self.date(2026, 2, 27, calendar: utc))
    }

    @Test("Changement d'heure : la période couvre le passage à l'heure d'été")
    func daylightSaving() {
        // Passage à l'heure d'été à Paris le 29 mars 2026.
        let p = period(Self.date(2026, 3, 29, 12), 15)
        #expect(p.start == Self.date(2026, 3, 15))
        #expect(p.end == Self.date(2026, 4, 15))
        #expect(p.end.timeIntervalSince(p.start) == 31 * 86_400 - 3_600)
    }

    @Test("Périodes suivante et précédente contiguës")
    func nextAndPrevious() {
        let p = period(Self.date(2026, 12, 30), 27)
        let next = p.next(calendar: Self.paris)
        #expect(next.start == p.end)
        #expect(next.end == Self.date(2027, 2, 27))
        #expect(next.previous(calendar: Self.paris) == p)
        #expect(p.preceding(6, calendar: Self.paris).map(\.start) == [
            Self.date(2026, 11, 27), Self.date(2026, 10, 27), Self.date(2026, 9, 27),
            Self.date(2026, 8, 27), Self.date(2026, 7, 27), Self.date(2026, 6, 27),
        ])
        #expect(p.preceding(0, calendar: Self.paris).isEmpty)
    }

    @Test("Propriété : chaque heure de deux années tombe dans une seule période valide", arguments: [1, 15, 27, 28])
    func coverage(startDay: Int) {
        var instant = Self.date(2023, 12, 1)
        let stop = Self.date(2025, 12, 31)
        var previous: BudgetPeriod?
        while instant < stop {
            let p = period(instant, startDay)
            #expect(p.contains(instant))
            #expect(Self.paris.component(.day, from: p.start) == startDay)
            #expect(Self.paris.component(.day, from: p.end) == startDay)
            #expect(Self.paris.dateComponents([.hour, .minute], from: p.start) == DateComponents(hour: 0, minute: 0))
            if let previous, previous != p {
                #expect(previous.end == p.start)
            }
            previous = p
            instant = instant.addingTimeInterval(3_600 * 7)
        }
    }
}
