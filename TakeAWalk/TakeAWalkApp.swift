import SwiftUI
import UserNotifications

@main
struct TakeAWalkApp: App {
    init() {
        Refresher.register()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
                    Refresher.scheduleNext()
                }
        }
    }
}
