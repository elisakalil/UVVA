import Core
import Foundation
import UserNotifications

/// The daily reminder as weekly local notifications, one per chosen day (YOU-R20).
struct LocalReminderScheduler: ReminderScheduling {
    static let idPrefix = "uvva.reminder."

    func requestPermission() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])) ?? false
    }

    func schedule(_ reminder: Reminder?) async {
        let center = UNUserNotificationCenter.current()
        let ours = await center.pendingNotificationRequests().map(\.identifier).filter { $0.hasPrefix(Self.idPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: ours)
        guard let reminder else { return }
        let content = UNMutableNotificationContent()
        content.title = String(localized: "UVVA")
        content.body = String(localized: "Five minutes for wine. Your next lesson is waiting.")
        for weekday in reminder.weekdays {
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: DateComponents(hour: reminder.hour, minute: reminder.minute, weekday: weekday), repeats: true)
            try? await center.add(UNNotificationRequest(identifier: Self.idPrefix + "\(weekday)", content: content, trigger: trigger))
        }
    }
}
