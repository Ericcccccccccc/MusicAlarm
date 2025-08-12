import Foundation
import SwiftUI
import Combine

@MainActor
class AlarmListViewModel: ObservableObject {
    @Published var alarms: [Alarm] = []
    
    private var alarmManager = AlarmManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
        loadAlarms()
    }
    
    private func setupBindings() {
        alarmManager.$alarms
            .receive(on: DispatchQueue.main)
            .assign(to: &$alarms)
    }
    
    func loadAlarms() {
        alarms = alarmManager.fetchAlarms()
    }
    
    func addAlarm(_ alarm: Alarm) {
        alarmManager.saveAlarm(alarm)
    }
    
    func updateAlarm(_ alarm: Alarm) {
        alarmManager.saveAlarm(alarm)
    }
    
    func deleteAlarm(_ alarm: Alarm) {
        alarmManager.deleteAlarm(alarm.id)
    }
    
    func deleteAlarms(at offsets: IndexSet) {
        for index in offsets {
            let alarm = alarms[index]
            deleteAlarm(alarm)
        }
    }
    
    private func mockAlarms() -> [Alarm] {
        let calendar = Calendar.current
        
        return [
            Alarm(
                time: calendar.date(bySettingHour: 7, minute: 30, second: 0, of: Date()) ?? Date(),
                isEnabled: true,
                repeatDays: [.monday, .tuesday, .wednesday, .thursday, .friday],
                spotifySongId: "1",
                label: "Morning Alarm"
            ),
            Alarm(
                time: calendar.date(bySettingHour: 6, minute: 0, second: 0, of: Date()) ?? Date(),
                isEnabled: false,
                repeatDays: [.saturday, .sunday],
                spotifySongId: "2",
                label: "Weekend Wake Up"
            ),
            Alarm(
                time: calendar.date(bySettingHour: 22, minute: 0, second: 0, of: Date()) ?? Date(),
                isEnabled: true,
                repeatDays: [],
                spotifySongId: nil,
                label: "Bedtime Reminder"
            ),
            Alarm(
                time: calendar.date(bySettingHour: 15, minute: 30, second: 0, of: Date()) ?? Date(),
                isEnabled: false,
                repeatDays: [.monday, .wednesday, .friday],
                spotifySongId: "3",
                label: "Workout Time"
            )
        ]
    }
}