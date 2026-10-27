import BackgroundTasks
import CoreLocation
import UserNotifications
import WidgetKit

/// Coordinates a refresh: fetch, save for the widget, and notify on a change into ideal.
enum Refresher {
    /// Target cadence. iOS decides the actual timing.
    static let interval: TimeInterval = 30 * 60

    static func register() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: AppGroup.refreshTaskID, using: nil) { task in
            guard let refreshTask = task as? BGAppRefreshTask else { return }
            handleBackground(refreshTask)
        }
    }

    static func scheduleNext() {
        let request = BGAppRefreshTaskRequest(identifier: AppGroup.refreshTaskID)
        request.earliestBeginDate = Date(timeIntervalSinceNow: interval)
        try? BGTaskScheduler.shared.submit(request)
    }

    static func refresh(location: CLLocation) async throws -> WeatherSnapshot {
        let snapshot = try await WeatherFetcher.fetch(for: location)
        SharedStore.save(snapshot)
        SharedStore.saveLocation(location)
        WidgetCenter.shared.reloadAllTimelines()

        if snapshot.isIdeal && !SharedStore.lastIdeal {
            notifyIdeal()
        }
        SharedStore.lastIdeal = snapshot.isIdeal
        return snapshot
    }

    private static func handleBackground(_ task: BGAppRefreshTask) {
        scheduleNext()
        let work = Task {
            var success = false
            if let location = SharedStore.lastLocation {
                success = (try? await refresh(location: location)) != nil
            }
            task.setTaskCompleted(success: success)
        }
        task.expirationHandler = { work.cancel() }
    }

    private static func notifyIdeal() {
        let content = UNMutableNotificationContent()
        content.title = "Good time for a walk"
        content.body = "Conditions where you are are ideal right now."
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
}
