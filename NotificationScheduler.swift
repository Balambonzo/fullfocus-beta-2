import Foundation

final class NotificationScheduler {

    static let shared = NotificationScheduler()

    private init() {}

    func refreshSchedule() {

        NotificationManager.shared.removeAllPending()

        let calendar = Calendar.current

        let now = Date()

        let tomorrow = calendar.startOfDay(
            for: calendar.date(
                byAdding: .day,
                value: 1,
                to: now
            )!
        )

        let expiration = calendar.date(
            byAdding: .second,
            value: -1,
            to: tomorrow
        )!
        
        // Reminder delle 19:00

        let sevenPM = calendar.date(
            bySettingHour: 19,
            minute: 0,
            second: 0,
            of: now
        )!

        scheduleReminder(
            id: "7pm",
            date: sevenPM,
            message: MotivationalNotifications.randomWarning()
        )

        scheduleReminder(
            id: "6h",
            date: expiration.addingTimeInterval(-21600),
            message: MotivationalNotifications.randomWarning()
        )

        scheduleReminder(
            id: "2h",
            date: expiration.addingTimeInterval(-7200),
            message: MotivationalNotifications.randomWarning()
        )

        scheduleReminder(
            id: "30m",
            date: expiration.addingTimeInterval(-1800),
            message: MotivationalNotifications.randomFinalWarning()
        )

        scheduleReminder(
            id: "inactive",
            date: now.addingTimeInterval(60*60*24*3),
            message: MotivationalNotifications.randomInactivity()
        )

    }

    private func scheduleReminder(
        id: String,
        date: Date,
        message: String
    ) {

        guard date > Date() else {
            return
        }

        NotificationManager.shared.schedule(
            id: id,
            title: "Full Focus",
            body: message,
            date: date
        )

    }

}
