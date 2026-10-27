import Foundation
import Observation

@Observable
@MainActor
final class WeatherViewModel {
    private(set) var snapshot: WeatherSnapshot? = SharedStore.load()
    private(set) var errorMessage: String?
    private let location = LocationProvider()

    var lastUpdated: Date? { snapshot?.fetchedAt }

    /// Stale data (older than 2 hours) never shows as ideal.
    var isIdeal: Bool {
        guard let snapshot, Date().timeIntervalSince(snapshot.fetchedAt) < 2 * 3600 else { return false }
        return snapshot.isIdeal
    }

    func refresh() async {
        do {
            let here = try await location.currentLocation()
            snapshot = try await Refresher.refresh(location: here)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
