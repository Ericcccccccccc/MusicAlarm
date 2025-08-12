import Foundation

struct Alarm: Identifiable, Codable {
    let id = UUID()
    var time: Date
    var repeatDays: Set<Weekday>
    var isEnabled: Bool
    var spotifySongId: String?
    var label: String
    var snoozeEnabled: Bool
    var soundVolume: Float
    
    init(time: Date = Date(), isEnabled: Bool = true, repeatDays: Set<Weekday> = [], spotifySongId: String? = nil, label: String = "Alarm", snoozeEnabled: Bool = true, soundVolume: Float = 0.8) {
        self.time = time
        self.isEnabled = isEnabled
        self.repeatDays = repeatDays
        self.spotifySongId = spotifySongId
        self.label = label
        self.snoozeEnabled = snoozeEnabled
        self.soundVolume = soundVolume
    }
}

enum Weekday: String, CaseIterable, Codable {
    case monday = "Mon"
    case tuesday = "Tue"
    case wednesday = "Wed"
    case thursday = "Thu"
    case friday = "Fri"
    case saturday = "Sat"
    case sunday = "Sun"
    
    var fullName: String {
        switch self {
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        case .sunday: return "Sunday"
        }
    }
}

protocol AlarmManagerProtocol {
    func fetchAlarms() -> [Alarm]
    func saveAlarm(_ alarm: Alarm)
    func deleteAlarm(_ id: UUID)
}