import SwiftUI

struct LogsView: View {
    @State private var logs: [ConditionLog] = []
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            Group {
                if logs.isEmpty {
                    ContentUnavailableView("No Logs Collected Yet", systemImage: "tray")
                } else {
                    List {
                        ForEach(groupedByDay, id: \.day) { group in
                            Section(group.day.formatted(date: .complete, time: .omitted)) {
                                ForEach(group.logs) { log in
                                    NavigationLink {
                                        LogDetailView(log: log)
                                    } label: {
                                        LogRow(log: log)
                                    }
                                }
                                .onDelete { offsets in
                                    delete(group.logs, at: offsets)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable { reload() }
            .onAppear { reload() }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active { reload() }
            }
        }
    }

    /// Logs grouped by day, newest day first.
    private var groupedByDay: [(day: Date, logs: [ConditionLog])] {
        let grouped = Dictionary(grouping: logs) { Calendar.current.startOfDay(for: $0.pressedAt) }
        return grouped
            .map { (day: $0.key, logs: $0.value.sorted { $0.pressedAt > $1.pressedAt }) }
            .sorted { $0.day > $1.day }
    }

    private func reload() {
        logs = LogStore.load().sorted { $0.pressedAt > $1.pressedAt }
    }

    private func delete(_ dayLogs: [ConditionLog], at offsets: IndexSet) {
        let ids = Set(offsets.map { dayLogs[$0].id })
        LogStore.delete(ids: ids)
        reload()
    }
}

/// One compact line per log: feeling, time pressed, and a short summary.
struct LogRow: View {
    let log: ConditionLog

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: log.feeling.symbol)
                .font(.title3)
                .foregroundStyle(log.feeling.color)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(log.feeling.title)
                        .font(.subheadline.bold())
                    Spacer()
                    Text(log.pressedAt.formatted(date: .omitted, time: .shortened))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Text(shortSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                if let counted = countedLine {
                    counted
                        .font(.caption2)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, 2)
    }

    /// Each counted attribute with ✓ if it was in range, ✗ if not.
    private var countedLine: Text? {
        guard let criteria = log.criteria else { return nil }
        let active = criteria.filter(\.isActive)
        guard !active.isEmpty else { return nil }
        return active.enumerated().reduce(Text("")) { result, item in
            let (index, c) = item
            let ok = IdealRule.status(of: c, values: log.values) == .inRange
            let separator = index == 0 ? "" : "  "
            return result
                + Text(separator + c.attribute.title + " ")
                + Text(ok ? "✓" : "✗").foregroundColor(ok ? .green : .red)
        }
    }

    private var shortSummary: String {
        guard !log.values.isEmpty else { return "No weather data" }
        var parts: [String] = []
        if let condition = log.extras?.condition { parts.append(condition) }
        if let temp = log.values[Attribute.actualTemp.rawValue] {
            parts.append(Attribute.actualTemp.format(temp))
        }
        if let chance = log.values[Attribute.precipChance.rawValue] {
            parts.append("\(Attribute.precipChance.format(chance)) rain")
        }
        return parts.joined(separator: " · ")
    }
}

/// Every stored detail for one log, including the separate times.
struct LogDetailView: View {
    let log: ConditionLog

    var body: some View {
        List {
            Section("When") {
                LabeledContent("Pressed", value: stamp(log.pressedAt))
                if abs(log.recordedAt.timeIntervalSince(log.pressedAt)) >= 1 {
                    LabeledContent("Recorded", value: stamp(log.recordedAt))
                }
                if let received = log.responseReceivedAt {
                    LabeledContent("Weather received", value: stamp(received))
                }
                if let observed = log.observedAt {
                    LabeledContent("Observed", value: stamp(observed))
                }
            }

            Section("Conditions") {
                if let condition = log.extras?.condition {
                    LabeledContent("Condition", value: condition)
                }
                if let trend = log.extras?.pressureTrend {
                    LabeledContent("Pressure trend", value: trend)
                }
                if let dew = log.extras?.dewPointF {
                    LabeledContent("Dew point", value: "\(Int(dew.rounded()))°")
                }
                if let direction = log.extras?.windCompassDirection {
                    LabeledContent("Wind direction", value: direction)
                }
                ForEach(Attribute.allCases) { attribute in
                    if let v = log.values[attribute.rawValue] {
                        LabeledContent(attribute.title, value: attribute.format(v))
                    }
                }
            }

            if let criteria = log.criteria {
                Section("Ideal rule at log time") {
                    if let ideal = log.wasIdeal {
                        LabeledContent("Ideal", value: ideal ? "Yes" : "No")
                    }
                    ForEach(criteria.filter(\.isActive)) { c in
                        let status = IdealRule.status(of: c, values: log.values)
                        LabeledContent(c.attribute.title) {
                            HStack {
                                Text(valueText(for: c.attribute))
                                Text(c.attribute.isBoolean
                                     ? "(\(c.attribute.format(c.lower)))"
                                     : "(\(c.attribute.format(c.lower))–\(c.attribute.format(c.upper)))")
                                    .foregroundStyle(.secondary)
                                Text(status == .inRange ? "✓" : "✗")
                                    .foregroundColor(status == .inRange ? .green : .red)
                            }
                        }
                    }
                }
            }

            if let lat = log.latitude, let lon = log.longitude {
                Section("Location") {
                    LabeledContent("Latitude", value: String(format: "%.4f", lat))
                    LabeledContent("Longitude", value: String(format: "%.4f", lon))
                }
            }
        }
        .navigationTitle(log.feeling.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func valueText(for attribute: Attribute) -> String {
        guard let v = log.values[attribute.rawValue] else { return "—" }
        return attribute.format(v)
    }

    private func stamp(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .standard)
    }
}
