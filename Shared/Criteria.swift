import Foundation

/// The 12 attributes shown as circles. The raw value is the storage key.
enum Attribute: String, Codable, CaseIterable, Identifiable {
    case actualTemp, perceivedTemp, cloudCover, humidity, precipIntensity, precipChance
    case windSpeed, windGust, uvIndex, visibility, pressure, daylight

    var id: String { rawValue }

    var title: String {
        switch self {
        case .actualTemp: return "Actual temp"
        case .perceivedTemp: return "Feels like"
        case .cloudCover: return "Cloud cover"
        case .humidity: return "Humidity"
        case .precipIntensity: return "Precip amount"
        case .precipChance: return "Precip chance"
        case .windSpeed: return "Wind speed"
        case .windGust: return "Wind gust"
        case .uvIndex: return "UV index"
        case .visibility: return "Visibility"
        case .pressure: return "Pressure"
        case .daylight: return "Daylight"
        }
    }

    var unit: String {
        switch self {
        case .actualTemp, .perceivedTemp: return "°F"
        case .cloudCover, .humidity, .precipChance: return "%"
        case .windSpeed, .windGust: return "mph"
        case .visibility: return "mi"
        case .pressure: return "inHg"
        case .precipIntensity: return "mm"
        case .uvIndex, .daylight: return ""
        }
    }

    /// Default ideal range, in the units above. Daylight is 1...1 (must be true).
    var defaultRange: ClosedRange<Double> {
        switch self {
        case .actualTemp: return 56...68
        case .perceivedTemp: return 56...68
        case .cloudCover: return 0...50
        case .humidity: return 0...100
        case .precipIntensity: return 0...0
        case .precipChance: return 0...20
        case .windSpeed: return 0...20
        case .windGust: return 0...30
        case .uvIndex: return 0...11
        case .visibility: return 0...10
        case .pressure: return 29.0...31.0
        case .daylight: return 1...1
        }
    }

    /// Range the sliders can move across.
    var sliderRange: ClosedRange<Double> {
        switch self {
        case .actualTemp, .perceivedTemp: return -20...110
        case .pressure: return 28...32
        case .precipIntensity: return 0...10
        case .uvIndex: return 0...11
        case .visibility: return 0...10
        case .windSpeed, .windGust: return 0...80
        case .daylight: return 0...1
        default: return 0...100
        }
    }

    var defaultActive: Bool {
        switch self {
        case .actualTemp, .cloudCover, .precipIntensity, .precipChance, .daylight: return true
        default: return false
        }
    }

    var isBoolean: Bool { self == .daylight }

    func format(_ v: Double) -> String {
        switch self {
        case .actualTemp, .perceivedTemp: return "\(Int(v.rounded()))°"
        case .cloudCover, .humidity, .precipChance: return "\(Int(v.rounded()))%"
        case .precipIntensity: return String(format: "%.1f mm", v)
        case .windSpeed, .windGust: return "\(Int(v.rounded())) mph"
        case .uvIndex: return "\(Int(v.rounded()))"
        case .visibility: return String(format: "%.1f mi", v)
        case .pressure: return String(format: "%.2f inHg", v)
        case .daylight: return v == 1 ? "Day" : "Night"
        }
    }
}

/// One attribute's ideal range and whether it counts toward "ideal".
struct Criterion: Codable, Equatable, Identifiable {
    var attribute: Attribute
    var lower: Double
    var upper: Double
    var isActive: Bool

    var id: Attribute { attribute }

    static var defaults: [Criterion] {
        Attribute.allCases.map { a in
            Criterion(
                attribute: a,
                lower: a.defaultRange.lowerBound,
                upper: a.defaultRange.upperBound,
                isActive: a.defaultActive
            )
        }
    }
}

/// The ideal rule: ideal when every active criterion is in range.
enum IdealRule {
    enum Status {
        case inRange, outOfRange, inactive, unknown
    }

    /// `values` are keyed by Attribute.rawValue, in display units. Nil means no fresh data.
    static func status(of c: Criterion, values: [String: Double]?) -> Status {
        guard c.isActive else { return .inactive }
        guard let v = values?[c.attribute.rawValue] else { return .unknown }
        return (c.lower...c.upper).contains(v) ? .inRange : .outOfRange
    }

    static func isIdeal(criteria: [Criterion], values: [String: Double]?) -> Bool {
        criteria.filter(\.isActive).allSatisfy { status(of: $0, values: values) == .inRange }
    }
}
