import AppIntents
import SwiftUI
import WidgetKit

struct IdealEntry: TimelineEntry {
    let date: Date
    let isIdeal: Bool
    /// True for one second after a button press, to confirm the log.
    var justLogged: Bool = false
    /// The button that was pressed, shown with "Logged" while justLogged is true.
    var loggedFeeling: LogFeeling? = nil
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

    private func entries() -> [IdealEntry] {
        let now = Date()
        let base = baseEntries(now: now)

        // Right after a press, show the confirmation for one second, then return to normal.
        if let logged = SharedStore.lastLoggedAt, now.timeIntervalSince(logged) < 1 {
            let ideal = base.first?.isIdeal ?? false
            let feeling = SharedStore.lastLoggedFeeling
            return [
                IdealEntry(date: logged, isIdeal: ideal, justLogged: true, loggedFeeling: feeling),
                IdealEntry(date: logged.addingTimeInterval(1), isIdeal: ideal),
            ] + base.dropFirst()
        }
        return base
    }

    /// Current state, then one entry per upcoming hour. Snapshots older than 2 hours show as not ideal.
    private func baseEntries(now: Date) -> [IdealEntry] {
        guard let snapshot = SharedStore.load() else {
            return [IdealEntry(date: now, isIdeal: false)]
        }
        let criteria = SharedStore.criteria
        let fresh = now.timeIntervalSince(snapshot.fetchedAt) < 2 * 3600

        var result = [
            IdealEntry(
                date: now,
                isIdeal: fresh && IdealRule.isIdeal(criteria: criteria, values: snapshot.values)
            )
        ]
        result += snapshot.hourly
            .filter { $0.date > now }
            .map { hour in
                IdealEntry(
                    date: hour.date,
                    isIdeal: fresh && IdealRule.isIdeal(criteria: criteria, values: hour.values)
                )
            }
        return result
    }
}

/// Small square widget: the status door fills the top half, and Good and Bad buttons fill the bottom half.
struct IdealWidgetView: View {
    let entry: IdealEntry

    var body: some View {
        VStack(spacing: 0) {
            StatusDoor(isIdeal: entry.isIdeal, size: 72)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            HStack(spacing: 8) {
                button(.positive)
                button(.negative)
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 12)
        }
        .padding(.top, 6)
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private func button(_ feeling: LogFeeling) -> some View {
        let pressed = entry.justLogged && entry.loggedFeeling == feeling
        let tint = feeling == .positive
            ? Color(red: 0.30, green: 0.66, blue: 0.42)
            : Color(red: 0.82, green: 0.36, blue: 0.30)
        return Button(intent: LogConditionIntent(feeling: feeling)) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(tint)

                // The thumb turns into a checkmark for one second after a press, then back.
                Image(systemName: pressed ? "checkmark" : feeling.symbol)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .padding(10)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
        .description("Shows whether conditions are good to go out, and logs how they feel.")
        .supportedFamilies([.systemSmall])
    }
}
