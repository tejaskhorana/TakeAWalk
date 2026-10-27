import CoreLocation
import Foundation

enum AppGroup {
    static let id = "group.com.tejaskhorana.TakeAWalk"
    static let refreshTaskID = "com.tejaskhorana.TakeAWalk.refresh"
}

/// One hour of forecast. Values are keyed by Attribute.rawValue, in display units.
struct HourlyPoint: Codable {
    let date: Date
    let values: [String: Double]
}

/// Non-numeric and extra current-conditions fields, saved with each log.
struct ExtraConditions: Codable {
    var condition: String?
    var pressureTrend: String?
    var dewPointF: Double?
    var windDirectionDegrees: Double?
    var windCompassDirection: String?
}

/// Current conditions plus the hourly series the widget uses.
struct WeatherSnapshot: Codable {
    var fetchedAt: Date
    var values: [String: Double]
    var observedAt: Date?
    var extras: ExtraConditions?
    var hourly: [HourlyPoint]
}

/// App Group storage shared between the app and the widget.
enum SharedStore {
    private static var defaults: UserDefaults? { UserDefaults(suiteName: AppGroup.id) }
    private static let snapshotKey = "snapshot"
    private static let criteriaKey = "criteria"
    private static let lastIdealKey = "lastIdeal"
    private static let latKey = "lastLat"
    private static let lonKey = "lastLon"

    static func save(_ snapshot: WeatherSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults?.set(data, forKey: snapshotKey)
    }

    static func load() -> WeatherSnapshot? {
        guard let data = defaults?.data(forKey: snapshotKey) else { return nil }
        return try? JSONDecoder().decode(WeatherSnapshot.self, from: data)
    }

    /// User's ideal settings. Missing attributes fall back to defaults.
    static var criteria: [Criterion] {
        get {
            let saved: [Criterion] = defaults?.data(forKey: criteriaKey)
                .flatMap { try? JSONDecoder().decode([Criterion].self, from: $0) } ?? []
            return Attribute.allCases.map { a in
                saved.first { $0.attribute == a } ?? Criterion.defaults.first { $0.attribute == a }!
            }
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue) else { return }
            defaults?.set(data, forKey: criteriaKey)
        }
    }

    /// Number of widget button presses this phone has received (for diagnostics).
    static var pressCount: Int {
        get { defaults?.integer(forKey: "pressCount") ?? 0 }
        set { defaults?.set(newValue, forKey: "pressCount") }
    }

    /// When the last log was saved. The widget shows "Logged" for a short time after this.
    static var lastLoggedAt: Date? {
        get { defaults?.object(forKey: "lastLoggedAt") as? Date }
        set { defaults?.set(newValue, forKey: "lastLoggedAt") }
    }

    static var lastLoggedFeeling: LogFeeling? {
        get { defaults?.string(forKey: "lastLoggedFeeling").flatMap(LogFeeling.init(rawValue:)) }
        set { defaults?.set(newValue?.rawValue, forKey: "lastLoggedFeeling") }
    }

    /// Last ideal state, so notifications fire only on a change into ideal.
    static var lastIdeal: Bool {
        get { defaults?.bool(forKey: lastIdealKey) ?? false }
        set { defaults?.set(newValue, forKey: lastIdealKey) }
    }

    /// Last foreground location, used by background refresh.
    static func saveLocation(_ location: CLLocation) {
        defaults?.set(location.coordinate.latitude, forKey: latKey)
        defaults?.set(location.coordinate.longitude, forKey: lonKey)
    }

    static var lastLocation: CLLocation? {
        guard let d = defaults, d.object(forKey: latKey) != nil else { return nil }
        return CLLocation(latitude: d.double(forKey: latKey), longitude: d.double(forKey: lonKey))
    }
}
