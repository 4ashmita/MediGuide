import UserNotifications
import Foundation

enum NotificationManager {

    private static let checkInIdentifier = "mediguide.reassessment.checkin"

    static func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    static func scheduleCheckIn(in seconds: Int, tier: RecommendationTier) {
        cancelCheckIn()

        let content = UNMutableNotificationContent()
        content.title = "Time to Check In"
        content.body = "How are they doing now? Tap to update."
        content.sound = .default
        content.badge = 1

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(seconds), repeats: false)
        let request = UNNotificationRequest(identifier: checkInIdentifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    static func cancelCheckIn() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [checkInIdentifier])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [checkInIdentifier])
        UNUserNotificationCenter.current().setBadgeCount(0, withCompletionHandler: nil)
    }
}
