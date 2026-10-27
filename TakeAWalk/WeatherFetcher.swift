import CoreLocation
import Foundation
import WeatherKit

/// Fetches current conditions and the hourly forecast from Apple WeatherKit,
/// and converts everything to display units (°F, %, mph, mi, inHg, mm).
enum WeatherFetcher {
    static func fetch(for location: CLLocation) async throws -> WeatherSnapshot {
        let (current, hourlyForecast) = try await WeatherService.shared.weather(
            for: location,
            including: .current, .hourly
        )

        func f(_ t: Measurement<UnitTemperature>) -> Double { t.converted(to: .fahrenheit).value }
        func pct(_ fraction: Double) -> Double { (fraction * 100).rounded() }

        let hours = Array(hourlyForecast.prefix(24))

        // Precipitation amount for the current hour, in mm.
        let nowPrecipMm = hours.first?.precipitationAmount.converted(to: .millimeters).value ?? 0

        var values: [String: Double] = [
            Attribute.actualTemp.rawValue: f(current.temperature),
            Attribute.perceivedTemp.rawValue: f(current.apparentTemperature),
            Attribute.cloudCover.rawValue: pct(current.cloudCover),
            Attribute.humidity.rawValue: pct(current.humidity),
            Attribute.precipIntensity.rawValue: nowPrecipMm,
            Attribute.windSpeed.rawValue: current.wind.speed.converted(to: .milesPerHour).value,
            Attribute.uvIndex.rawValue: Double(current.uvIndex.value),
            Attribute.visibility.rawValue: current.visibility.converted(to: .miles).value,
            Attribute.pressure.rawValue: current.pressure.converted(to: .inchesOfMercury).value,
            Attribute.daylight.rawValue: current.isDaylight ? 1 : 0,
        ]
        if let gust = current.wind.gust {
            values[Attribute.windGust.rawValue] = gust.converted(to: .milesPerHour).value
        }
        if let next = hours.first {
            values[Attribute.precipChance.rawValue] = pct(next.precipitationChance)
        }

        let extras = ExtraConditions(
            condition: String(describing: current.condition),
            pressureTrend: String(describing: current.pressureTrend),
            dewPointF: f(current.dewPoint),
            windDirectionDegrees: current.wind.direction.converted(to: .degrees).value,
            windCompassDirection: String(describing: current.wind.compassDirection)
        )

        let hourly = hours.map { hour -> HourlyPoint in
            var v: [String: Double] = [
                Attribute.actualTemp.rawValue: f(hour.temperature),
                Attribute.perceivedTemp.rawValue: f(hour.apparentTemperature),
                Attribute.cloudCover.rawValue: pct(hour.cloudCover),
                Attribute.humidity.rawValue: pct(hour.humidity),
                Attribute.precipChance.rawValue: pct(hour.precipitationChance),
                Attribute.precipIntensity.rawValue: hour.precipitationAmount.converted(to: .millimeters).value,
                Attribute.windSpeed.rawValue: hour.wind.speed.converted(to: .milesPerHour).value,
                Attribute.uvIndex.rawValue: Double(hour.uvIndex.value),
                Attribute.visibility.rawValue: hour.visibility.converted(to: .miles).value,
                Attribute.pressure.rawValue: hour.pressure.converted(to: .inchesOfMercury).value,
                Attribute.daylight.rawValue: hour.isDaylight ? 1 : 0,
            ]
            if let gust = hour.wind.gust {
                v[Attribute.windGust.rawValue] = gust.converted(to: .milesPerHour).value
            }
            return HourlyPoint(date: hour.date, values: v)
        }

        return WeatherSnapshot(
            fetchedAt: Date(),
            values: values,
            observedAt: current.date,
            extras: extras,
            hourly: hourly
        )
    }
}
