import AppIntents
import Foundation
import SwiftUI

/// How the conditions felt. Used by the widget buttons.
enum LogFeeling: String, Codable, CaseIterable, AppEnum {
    case positive, neutral, negative

    static var typeDisplayRepresentation: TypeDisplayRepresentation = TypeDisplayRepresentation(name: LocalizedStringResource("Feeling"))

    static var caseDisplayRepresentations: [LogFeeling: DisplayRepresentation] = [
        .positive: DisplayRepresentation(title: LocalizedStringResource("Good")),
        .neutral: DisplayRepresentation(title: LocalizedStringResource("Okay")),
        .negative: DisplayRepresentation(title: LocalizedStringResource("Bad")),
    ]

    var title: String {
        switch self {
        case .positive: return "Good"
        case .neutral: return "Okay"
        case .negative: return "Bad"
        }
    }

    var symbol: String {
        switch self {
        case .positive: return "hand.thumbsup.fill"
        case .neutral: return "minus.circle.fill"
        case .negative: return "hand.thumbsdown.fill"
        }
    }

    var color: Color {
        switch self {
        case .positive: return .green
        case .neutral: return .gray
        case .negative: return .red
        }
    }
}

/// One logged moment. Times are kept separately because they differ:
/// - pressedAt: when the button was tapped
/// - recordedAt: when the log was written to storage
/// - responseReceivedAt: when this phone last received WeatherKit data
/// - observedAt: WeatherKit's time for the current conditions
struct ConditionLog: Codable, Identifiable {
    let id: UUID
    let feeling: LogFeeling
    let pressedAt: Date
    let recordedAt: Date
    let responseReceivedAt: Date?
    let observedAt: Date?
    /// Same keys and display units as WeatherSnapshot.values.
    let values: [String: Double]
    /// Optional, so logs saved before this field existed still load.
    let extras: ExtraConditions?
    /// Whether conditions were ideal at log time, and the criteria used. Nil for older logs.
    let wasIdeal: Bool?
    let criteria: [Criterion]?
    let latitude: Double?
    let longitude: Double?
}

/// Logs stored as one JSON file in the shared App Group container, so the widget and app both see them.
enum LogStore {
    /// False when the shared App Group container is unavailable (usually an entitlement problem).
    static var isAvailable: Bool { fileURL != nil }

    private static var fileURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: AppGroup.id)?
            .appendingPathComponent("condition-logs.json")
    }

    static func load() -> [ConditionLog] {
        guard let url = fileURL, let data = try? Data(contentsOf: url) else { return [] }
        return (try? JSONDecoder().decode([ConditionLog].self, from: data)) ?? []
    }

    static func save(_ logs: [ConditionLog]) {
        guard let url = fileURL, let data = try? JSONEncoder().encode(logs) else { return }
        try? data.write(to: url, options: .atomic)
    }

    static func append(_ log: ConditionLog) {
        var logs = load()
        logs.append(log)
        save(logs)
    }

    static func delete(ids: Set<UUID>) {
        save(load().filter { !ids.contains($0.id) })
    }
}
