import Foundation

class PersistenceManager {
    static let shared = PersistenceManager()
    
    private let userDefaults = UserDefaults.standard
    private let alarmsKey = "SavedAlarms"
    
    private init() {}
    
    func fetchAlarms() -> [Alarm] {
        guard let data = userDefaults.data(forKey: alarmsKey) else { return [] }
        
        do {
            let alarms = try JSONDecoder().decode([Alarm].self, from: data)
            return alarms
        } catch {
            print("Error loading alarms: \(error)")
            return []
        }
    }
    
    private func saveAlarms(_ alarms: [Alarm]) {
        do {
            let data = try JSONEncoder().encode(alarms)
            userDefaults.set(data, forKey: alarmsKey)
        } catch {
            print("Error saving alarms: \(error)")
        }
    }
    
    func saveAlarm(_ alarm: Alarm) {
        var alarms = fetchAlarms()
        if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
            alarms[index] = alarm
        } else {
            alarms.append(alarm)
        }
        saveAlarms(alarms)
    }
    
    func updateAlarm(_ alarm: Alarm) {
        saveAlarm(alarm)
    }
    
    func deleteAlarm(_ id: UUID) {
        var alarms = fetchAlarms()
        alarms.removeAll { $0.id == id }
        saveAlarms(alarms)
    }
}