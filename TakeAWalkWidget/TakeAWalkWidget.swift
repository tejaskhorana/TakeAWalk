import SwiftUI
import WidgetKit

struct IdealEntry: TimelineEntry {
    let date: Date
    let isIdeal: Bool
}

struct IdealProvider: TimelineProvider {
    func placeholder(in context: Context) -> IdealEntry {
        IdealEntry(date: .now, isIdeal: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (IdealEntry) -> Void) {
        completion(entries().first ?? IdealEntry(date: .now, isIdeal: false))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<IdealEntry>) -> Void) {
        let next = Date().addingTimeInterval(30 * 60)
        completion(Timeline(entries: entries(), policy: .after(next)))
    }

    /// The current state, then one entry per upcoming hour from the stored forecast.
    /// Snapshots older than 2 hours show as not ideal.
    private func entries() -> [IdealEntry] {
        let now = Date()
        guard let snapshot = SharedStore.load() else {
            return [IdealEntry(date: now, isIdeal: false)]
        }
        let fresh = now.timeIntervalSince(snapshot.fetchedAt) < 2 * 3600
        var result = [IdealEntry(date: now, isIdeal: fresh && snapshot.isIdeal)]
        result += snapshot.hourly
            .filter { $0.date > now }
            .map { IdealEntry(date: $0.date, isIdeal: fresh && $0.isIdeal) }
        return result
    }
}

struct IdealWidgetView: View {
    let entry: IdealEntry

    var body: some View {
        Circle()
            .fill(entry.isIdeal ? Color.green : Color.clear)
            .overlay(Circle().strokeBorder(Color.secondary.opacity(0.4), lineWidth: 2))
            .padding(8)
            .containerBackground(.fill.tertiary, for: .widget)
    }
}

@main
struct TakeAWalkWidget: Widget {
    let kind = "TakeAWalkWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: IdealProvider()) { entry in
            IdealWidgetView(entry: entry)
        }
        .configurationDisplayName("TakeAWalk")
        .description("Green when conditions are ideal to be outside.")
        .supportedFamilies([.systemSmall])
    }
}
