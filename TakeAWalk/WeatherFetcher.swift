import CoreLocation
import Foundation
import WeatherKit

/// Fetches current conditions and the hourly forecast from Apple WeatherKit.
enum WeatherFetcher {
    static func fetch(for location: CLLocation) async throws -> WeatherSnapshot {
        let weather = try await WeatherService.shared.weather(for: location, including: .current, .hourly)
        let now = weather.currentWeather

        let hourly = weather.hourlyForecast.forecast.prefix(24).map { hour in
            HourlyPoint(
                date: hour.date,
                perceivedF: hour.apparentTemperature.converted(to: .fahrenheit).value
            )
        }

        return WeatherSnapshot(
            fetchedAt: Date(),
            actualF: now.temperature.converted(to: .fahrenheit).value,
            perceivedF: now.apparentTemperature.converted(to: .fahrenheit).value,
            cloudCover: now.cloudCover,
            humidity: now.humidity,
            precipitationIntensity: now.precipitationIntensity.value,
            windSpeedMph: now.wind.speed.converted(to: .milesPerHour).value,
            windGustMph: now.wind.gust?.converted(to: .milesPerHour).value,
            uvIndex: now.uvIndex.value,
            visibilityMiles: now.visibility.converted(to: .miles).value,
            pressureInHg: now.pressure.converted(to: .inchesOfMercury).value,
            dewPointF: now.dewPoint.converted(to: .fahrenheit).value,
            precipitationChance: weather.hourlyForecast.forecast.first?.precipitationChance ?? 0,
            hourly: Array(hourly)
        )
    }
}
