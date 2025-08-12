import Foundation
import UserNotifications
import SwiftUI

class AlarmManager: NSObject, AlarmManagerProtocol, ObservableObject {
    static let shared = AlarmManager()
    
    private let persistenceManager = PersistenceManager.shared
    private let notificationManager = NotificationManager.shared
    private let audioManager = AudioManager.shared
    
    @Published private(set) var alarms: [Alarm] = []
    
    override init() {
        super.init()
        setupNotificationDelegate()
        loadAlarms()
    }
    
    private func setupNotificationDelegate() {
        UNUserNotificationCenter.current().delegate = self
        notificationManager.setupNotificationCategories()
    }
    
    func fetchAlarms() -> [Alarm] {
        return alarms
    }
    
    func saveAlarm(_ alarm: Alarm) {
        if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
            alarms[index] = alarm
            persistenceManager.updateAlarm(alarm)
        } else {
            alarms.append(alarm)
            persistenceManager.saveAlarm(alarm)
        }
        
        if alarm.isEnabled {
            notificationManager.scheduleAlarm(alarm)
        } else {
            notificationManager.cancelAlarm(alarm)
        }
    }
    
    func deleteAlarm(_ id: UUID) {
        alarms.removeAll { $0.id == id }
        persistenceManager.deleteAlarm(id)
        
        if let alarm = alarms.first(where: { $0.id == id }) {
            notificationManager.cancelAlarm(alarm)
        }
    }
    
    func toggleAlarm(_ alarm: Alarm) {
        var updatedAlarm = alarm
        updatedAlarm.isEnabled.toggle()
        saveAlarm(updatedAlarm)
    }
    
    func snoozeAlarm(_ alarmId: UUID, snoozeMinutes: Int = 9) {
        guard let alarm = alarms.first(where: { $0.id == alarmId }),
              alarm.snoozeEnabled else { return }
        
        audioManager.stopAlarmSound()
        
        var snoozeAlarm = alarm
        snoozeAlarm.time = Calendar.current.date(byAdding: .minute, value: snoozeMinutes, to: Date()) ?? Date()
        snoozeAlarm.repeatDays = []
        
        notificationManager.scheduleAlarm(snoozeAlarm)
    }
    
    func stopAlarm(_ alarmId: UUID) {
        audioManager.stopAlarmSound()
    }
    
    private func loadAlarms() {
        alarms = persistenceManager.fetchAlarms()
    }
    
    func requestNotificationPermission() async -> Bool {
        return await notificationManager.requestAuthorization()
    }
    
    func rescheduleAllAlarms() {
        notificationManager.cancelAllAlarms()
        
        for alarm in alarms where alarm.isEnabled {
            notificationManager.scheduleAlarm(alarm)
        }
    }
    
    private func handleAlarmTrigger(_ alarmId: UUID, spotifySongId: String?, soundVolume: Float) {
        audioManager.setVolume(soundVolume)
        audioManager.playAlarmSound(spotifyURI: spotifySongId)
        audioManager.fadeIn(duration: 3.0)
    }
}

extension AlarmManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        let userInfo = notification.request.content.userInfo
        
        if let alarmIdString = userInfo["alarmId"] as? String,
           let alarmId = UUID(uuidString: alarmIdString) {
            
            let spotifySongId = userInfo["spotifySongId"] as? String
            let soundVolume = userInfo["soundVolume"] as? Float ?? 0.8
            
            handleAlarmTrigger(alarmId, spotifySongId: spotifySongId, soundVolume: soundVolume)
        }
        
        completionHandler([.alert, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo
        
        guard let alarmIdString = userInfo["alarmId"] as? String,
              let alarmId = UUID(uuidString: alarmIdString) else {
            completionHandler()
            return
        }
        
        switch response.actionIdentifier {
        case "SNOOZE_ACTION":
            snoozeAlarm(alarmId)
        case "STOP_ACTION", UNNotificationDefaultActionIdentifier:
            stopAlarm(alarmId)
        default:
            break
        }
        
        completionHandler()
    }
}