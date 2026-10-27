import Foundation
import Observation
import WidgetKit

@Observable
@MainActor
final class WeatherViewModel {
    private(set) var snapshot: WeatherSnapshot? = SharedStore.load()
    private(set) var criteria: [Criterion] = SharedStore.criteria
    private(set) var errorMessage: String?
    private let location = LocationProvider()

    var lastUpdated: Date? { snapshot?.fetchedAt }

    /// Values, but only when fresh (under 2 hours old). Stale data counts as unknown.
    var freshValues: [String: Double]? {
        guard let snapshot, Date().timeIntervalSince(snapshot.fetchedAt) < 2 * 3600 else { return nil }
        return snapshot.values
    }

    var isIdeal: Bool {
        IdealRule.isIdeal(criteria: criteria, values: freshValues)
    }

    func status(of criterion: Criterion) -> IdealRule.Status {
        IdealRule.status(of: criterion, values: freshValues)
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

    /// Saves one edited criterion, then updates the widget.
    func update(_ criterion: Criterion) {
        if let index = criteria.firstIndex(where: { $0.attribute == criterion.attribute }) {
            criteria[index] = criterion
        }
        SharedStore.criteria = criteria
        WidgetCenter.shared.reloadAllTimelines()
    }
}
