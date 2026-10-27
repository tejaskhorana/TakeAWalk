import CoreLocation
import Foundation

enum LocationError: LocalizedError {
    case denied

    var errorDescription: String? {
        "Location access is off. Turn it on in Settings to check conditions where you are."
    }
}

/// One-shot current location, requesting permission on first use.
/// Uses continuous updates and takes the first real fix, since a one-shot request
/// can fail with "location unknown" before the first fix arrives.
final class LocationProvider: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var pending: CheckedContinuation<CLLocation, Error>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = 1000 // meters; coarse is enough for weather
    }

    func currentLocation() async throws -> CLLocation {
        try await withCheckedThrowingContinuation { continuation in
            pending = continuation
            switch manager.authorizationStatus {
            case .notDetermined:
                manager.requestWhenInUseAuthorization()
            case .authorizedWhenInUse, .authorizedAlways:
                manager.startUpdatingLocation()
            default:
                finish(.failure(LocationError.denied))
            }
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            if pending != nil { manager.startUpdatingLocation() }
        case .denied, .restricted:
            finish(.failure(LocationError.denied))
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last { finish(.success(location)) }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // "Location unknown" is transient while the first fix is pending. Keep waiting.
        if let clError = error as? CLError, clError.code == .locationUnknown { return }
        finish(.failure(error))
    }

    private func finish(_ result: Result<CLLocation, Error>) {
        manager.stopUpdatingLocation()
        guard let continuation = pending else { return }
        pending = nil
        continuation.resume(with: result)
    }
}
