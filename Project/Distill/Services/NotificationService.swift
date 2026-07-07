import Foundation
import UserNotifications

/// Manages the two daily notifications Distill offers:
///
/// - **Reminder** — time-sensitive, breaks through Focus modes.
///   Default: 9 PM. Tells the user the day is almost over and they haven't
///   captured their moment yet.
///
/// - **Nudge** — a gentle mid-day prompt to look for something worth painting.
///   Default: 2 PM. Delivered as a regular active notification.
///
/// Settings (enabled flags + chosen times) are persisted in `UserDefaults` so
/// they survive app restarts. Mutations must happen on the main actor because
/// this type is `@Observable` and drives SwiftUI views.
@Observable
@MainActor
final class NotificationService {

    // MARK: - Notification Identifiers

    private enum NotificationID {
        static let reminder = "com.distill.notification.reminder"
        static let nudge    = "com.distill.notification.nudge"
    }

    // MARK: - UserDefaults Keys

    private enum Key {
        static let reminderEnabled = "notif.reminder.enabled"
        static let reminderHour    = "notif.reminder.hour"
        static let reminderMinute  = "notif.reminder.minute"
        static let nudgeEnabled    = "notif.nudge.enabled"
        static let nudgeHour       = "notif.nudge.hour"
        static let nudgeMinute     = "notif.nudge.minute"
    }

    // MARK: - Observable State

    /// Whether the end-of-day time-sensitive reminder is turned on.
    private(set) var reminderEnabled: Bool

    /// The time at which the daily reminder fires (hour + minute only).
    private(set) var reminderTime: Date

    /// Whether the gentle mid-day nudge is turned on.
    private(set) var nudgeEnabled: Bool

    /// The time at which the gentle nudge fires (hour + minute only).
    private(set) var nudgeTime: Date

    /// Reflects the system's current notification authorization state.
    /// Refresh by calling `refreshAuthorizationStatus()`.
    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    // MARK: - Init

    init() {
        let ud = UserDefaults.standard
        reminderEnabled = ud.bool(forKey: Key.reminderEnabled)
        nudgeEnabled    = ud.bool(forKey: Key.nudgeEnabled)

        // Fall back to sensible defaults when the keys have never been written.
        reminderTime = Self.loadTime(
            hourKey: Key.reminderHour, minuteKey: Key.reminderMinute,
            defaultHour: 21, defaultMinute: 0   // 9:00 PM
        )
        nudgeTime = Self.loadTime(
            hourKey: Key.nudgeHour, minuteKey: Key.nudgeMinute,
            defaultHour: 14, defaultMinute: 0   // 2:00 PM
        )
    }

    // MARK: - Public API

    /// Reads the current system authorization state and updates `authorizationStatus`.
    func refreshAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    /// Toggles the end-of-day reminder on or off.
    /// Requests notification permission the first time the user enables it.
    func setReminderEnabled(_ enabled: Bool) async {
        if enabled {
            guard await requestPermissionIfNeeded() else { return }
        }
        reminderEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: Key.reminderEnabled)
        updateReminderSchedule()
    }

    /// Updates the time the end-of-day reminder fires and reschedules it.
    func setReminderTime(_ time: Date) {
        reminderTime = time
        persistTime(time, hourKey: Key.reminderHour, minuteKey: Key.reminderMinute)
        if reminderEnabled { updateReminderSchedule() }
    }

    /// Toggles the gentle nudge on or off.
    /// Requests notification permission the first time the user enables it.
    func setNudgeEnabled(_ enabled: Bool) async {
        if enabled {
            guard await requestPermissionIfNeeded() else { return }
        }
        nudgeEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: Key.nudgeEnabled)
        updateNudgeSchedule()
    }

    /// Updates the time the gentle nudge fires and reschedules it.
    func setNudgeTime(_ time: Date) {
        nudgeTime = time
        persistTime(time, hourKey: Key.nudgeHour, minuteKey: Key.nudgeMinute)
        if nudgeEnabled { updateNudgeSchedule() }
    }

    // MARK: - Scheduling

    private func updateReminderSchedule() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [NotificationID.reminder])
        guard reminderEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "The day's almost over"
        content.body  = "You haven't painted yet. Capture today's moment before midnight."
        content.sound = .default
        // Time-sensitive notifications break through Focus modes.
        // Requires the com.apple.developer.usernotifications.time-sensitive
        // entitlement in the app's .entitlements file.
        content.interruptionLevel = .timeSensitive

        let request = UNNotificationRequest(
            identifier: NotificationID.reminder,
            content: content,
            trigger: dailyTrigger(from: reminderTime)
        )
        center.add(request)
    }

    private func updateNudgeSchedule() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [NotificationID.nudge])
        guard nudgeEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "Wish you a good painting today!"
        content.body  = "Take a look. Something nearby might be worth painting today."
        content.sound = .default
        // .active is the default interruption level — a standard notification.

        let request = UNNotificationRequest(
            identifier: NotificationID.nudge,
            content: content,
            trigger: dailyTrigger(from: nudgeTime)
        )
        center.add(request)
    }

    /// Builds a repeating `UNCalendarNotificationTrigger` that fires daily
    /// at the hour and minute encoded in `date`.
    private func dailyTrigger(from date: Date) -> UNCalendarNotificationTrigger {
        var components = Calendar.current.dateComponents([.hour, .minute], from: date)
        components.second = 0
        return UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
    }

    // MARK: - Permission

    /// Requests authorization if status is `.notDetermined`.
    /// Returns `true` when the app is (or becomes) authorized.
    @discardableResult
    private func requestPermissionIfNeeded() async -> Bool {
        let center   = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            authorizationStatus = .authorized
            return true

        case .notDetermined:
            let granted = (try? await center.requestAuthorization(
                options: [.alert, .sound, .badge]
            )) ?? false
            authorizationStatus = granted ? .authorized : .denied
            return granted

        case .denied:
            authorizationStatus = .denied
            return false

        @unknown default:
            return false
        }
    }

    // MARK: - UserDefaults Helpers

    private func persistTime(_ date: Date, hourKey: String, minuteKey: String) {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
        UserDefaults.standard.set(comps.hour   ?? 0, forKey: hourKey)
        UserDefaults.standard.set(comps.minute ?? 0, forKey: minuteKey)
    }

    private static func loadTime(
        hourKey: String, minuteKey: String,
        defaultHour: Int, defaultMinute: Int
    ) -> Date {
        let ud     = UserDefaults.standard
        let hour   = ud.object(forKey: hourKey)   != nil ? ud.integer(forKey: hourKey)   : defaultHour
        let minute = ud.object(forKey: minuteKey) != nil ? ud.integer(forKey: minuteKey) : defaultMinute

        var comps   = Calendar.current.dateComponents([.year, .month, .day], from: .now)
        comps.hour   = hour
        comps.minute = minute
        return Calendar.current.date(from: comps) ?? .now
    }
}
