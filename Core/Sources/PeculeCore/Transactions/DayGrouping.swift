import Foundation

public struct DayGroup<Element>: Identifiable {
    /// Minuit du jour, dans le fuseau du calendrier.
    public let day: Date
    public let items: [Element]
    public var id: Date { day }
}

public enum DayGrouping {
    /// Regroupe par jour, jours les plus récents d'abord, ordre interne préservé.
    public static func group<Element>(_ items: [Element], date: (Element) -> Date, calendar: Calendar) -> [DayGroup<Element>] {
        var buckets: [Date: [Element]] = [:]
        for item in items {
            buckets[calendar.startOfDay(for: date(item)), default: []].append(item)
        }
        return buckets.keys.sorted(by: >).map { DayGroup(day: $0, items: buckets[$0] ?? []) }
    }
}
