import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            return granted
        } catch {
            print("Error requesting notification authorization: \(error)")
            return false
        }
    }
    
    func scheduleAlarm(_ alarm: Alarm) {
        if alarm.repeatDays.isEmpty {
            scheduleOneTimeAlarm(alarm)
        } else {
            scheduleRepeatingAlarm(alarm)
        }
    }
    
    func cancelAlarm(_ alarm: Alarm) {
        let identifiers = alarm.repeatDays.isEmpty ? 
            [alarm.id.uuidString] : 
            alarm.repeatDays.map { "\(alarm.id.uuidString)-\($0.rawValue)" }
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    func cancelAllAlarms() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    private func scheduleOneTimeAlarm(_ alarm: Alarm) {
        let content = createNotificationContent(for: alarm)
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: alarm.time),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: alarm.id.uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling one-time alarm: \(error)")
            }
        }
    }
    
    private func scheduleRepeatingAlarm(_ alarm: Alarm) {
        for weekday in alarm.repeatDays {
            let content = createNotificationContent(for: alarm)
            
            var dateComponents = Calendar.current.dateComponents([.hour, .minute], from: alarm.time)
            dateComponents.weekday = weekdayToCalendarWeekday(weekday)
            
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: dateComponents,
                repeats: true
            )
            
            let request = UNNotificationRequest(
                identifier: "\(alarm.id.uuidString)-\(weekday.rawValue)",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling repeating alarm for \(weekday.rawValue): \(error)")
                }
            }
        }
    }
    
    private func createNotificationContent(for alarm: Alarm) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "Alarm"
        content.body = alarm.label
        content.sound = .default
        content.categoryIdentifier = "ALARM_CATEGORY"
        content.userInfo = [
            "alarmId": alarm.id.uuidString,
            "spotifySongId": alarm.spotifySongId as Any,
            "soundVolume": alarm.soundVolume,
            "snoozeEnabled": alarm.snoozeEnabled
        ]
        
        return content
    }
    
    private func weekdayToCalendarWeekday(_ weekday: Weekday) -> Int {
        switch weekday {
        case .sunday: return 1
        case .monday: return 2
        case .tuesday: return 3
        case .wednesday: return 4
        case .thursday: return 5
        case .friday: return 6
        case .saturday: return 7
        }
    }
    
    func setupNotificationCategories() {
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_ACTION",
            title: "Snooze",
            options: []
        )
        
        let stopAction = UNNotificationAction(
            identifier: "STOP_ACTION",
            title: "Stop",
            options: [.destructive]
        )
        
        let alarmCategory = UNNotificationCategory(
            identifier: "ALARM_CATEGORY",
            actions: [snoozeAction, stopAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([alarmCategory])
    }
}