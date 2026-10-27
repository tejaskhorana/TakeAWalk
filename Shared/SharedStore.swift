import CoreLocation
import Foundation

enum AppGroup {
    static let id = "group.com.tejaskhorana.TakeAWalk"
    static let refreshTaskID = "com.tejaskhorana.TakeAWalk.refresh"
}

/// The ideal rule. Perceived (apparent) temperature in °F, inclusive 60...70.
enum IdealRule {
    static let range: ClosedRange<Double> = 60...70
    static func isIdeal(perceivedF: Double) -> Bool { range.contains(perceivedF) }
}

struct HourlyPoint: Codable, Hashable {
    let date: Date
    let perceivedF: Double
    var isIdeal: Bool { IdealRule.isIdeal(perceivedF: perceivedF) }
}

/// Everything the app shows, plus the hourly series the widget uses.
/// Units: temperatures °F, wind mph, visibility miles, pressure inHg.
/// precipitationIntensity is stored in WeatherKit's native unit (not displayed yet).
struct WeatherSnapshot: Codable {
    var fetchedAt: Date
    var actualF: Double
    var perceivedF: Double
    var cloudCover: Double            // 0...1
    var humidity: Double              // 0...1
    var precipitationIntensity: Double
    var windSpeedMph: Double
    var windGustMph: Double?
    var uvIndex: Int
    var visibilityMiles: Double
    var pressureInHg: Double
    var dewPointF: Double
    var precipitationChance: Double   // 0...1, next hour
    var hourly: [HourlyPoint]

    var isIdeal: Bool { IdealRule.isIdeal(perceivedF: perceivedF) }
}

/// App Group storage shared between the app and the widget.
enum SharedStore {
    private static var defaults: UserDefaults? { UserDefaults(suiteName: AppGroup.id) }
    private static let snapshotKey = "snapshot"
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

    /// Last known ideal state, so notifications fire only on a change into ideal.
    static var lastIdeal: Bool {
        get { defaults?.bool(forKey: lastIdealKey) ?? false }
        set { defaults?.set(newValue, forKey: lastIdealKey) }
    }

    /// Last location seen in the foreground. Background refresh uses it,
    /// since iOS does not reliably provide location to background tasks.
    static func saveLocation(_ location: CLLocation) {
        defaults?.set(location.coordinate.latitude, forKey: latKey)
        defaults?.set(location.coordinate.longitude, forKey: lonKey)
    }

    static var lastLocation: CLLocation? {
        guard let d = defaults, d.object(forKey: latKey) != nil else { return nil }
        return CLLocation(latitude: d.double(forKey: latKey), longitude: d.double(forKey: lonKey))
    }
}
