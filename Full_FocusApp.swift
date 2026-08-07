import SwiftUI
import SwiftData

@main
struct Full_FocusApp: App {
    init() {
        NotificationManager.shared.requestAuthorization()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
                .onAppear {
                    NotificationScheduler.shared.refreshSchedule()
                }
        }
        .modelContainer(AppModelContainer.shared)
    }
}
