import SwiftUI
import WidgetKit

/// Extension Widgets. Vide en M1 : les vrais widgets (reste à dépenser) arrivent en M4.
@main
struct PeculeWidgets: WidgetBundle {
    var body: some Widget {
        PlaceholderWidget()
    }
}

nonisolated struct PlaceholderEntry: TimelineEntry {
    let date: Date
}

nonisolated struct PlaceholderProvider: TimelineProvider {
    func placeholder(in context: Context) -> PlaceholderEntry {
        PlaceholderEntry(date: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (PlaceholderEntry) -> Void) {
        completion(PlaceholderEntry(date: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PlaceholderEntry>) -> Void) {
        completion(Timeline(entries: [PlaceholderEntry(date: .now)], policy: .never))
    }
}

struct PlaceholderWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "PeculePlaceholder", provider: PlaceholderProvider()) { _ in
            VStack(spacing: 4) {
                Image(systemName: "eurosign.circle")
                    .font(.title)
                Text("Pécule")
                    .font(.headline)
            }
            .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Pécule")
        .description("Bientôt : votre reste à dépenser.")
        .supportedFamilies([.systemSmall])
    }
}
