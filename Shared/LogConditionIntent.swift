import AppIntents
import Foundation
import WidgetKit

/// Runs when a widget button is tapped. It saves the last weather data this phone received,
/// plus whether conditions counted as ideal at that moment, so it works without a network call.
struct LogConditionIntent: AppIntent {
    static var title: LocalizedStringResource = "Log conditions"
    static var description = IntentDescription("Saves the current conditions with how they felt.")

    /// Stay in the widget. Do not open the app.
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Feeling")
    var feeling: LogFeeling

    init() {}

    init(feeling: LogFeeling) {
        self.feeling = feeling
    }

    func perform() async throws -> some IntentResult {
        let pressedAt = Date()
        SharedStore.pressCount += 1

        let snapshot = SharedStore.load()
        let location = SharedStore.lastLocation
        let criteria = SharedStore.criteria

        let log = ConditionLog(
            id: UUID(),
            feeling: feeling,
            pressedAt: pressedAt,
            recordedAt: Date(),
            responseReceivedAt: snapshot?.fetchedAt,
            observedAt: snapshot?.observedAt,
            values: snapshot?.values ?? [:],
            extras: snapshot?.extras,
            wasIdeal: IdealRule.isIdeal(criteria: criteria, values: snapshot?.values),
            criteria: criteria,
            latitude: location?.coordinate.latitude,
            longitude: location?.coordinate.longitude
        )
        LogStore.append(log)
        SharedStore.lastLoggedAt = Date()
        SharedStore.lastLoggedFeeling = feeling
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
