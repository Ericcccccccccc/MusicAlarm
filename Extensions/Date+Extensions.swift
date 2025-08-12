import Foundation

extension Date {
    var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    var hourMinuteString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: self)
    }
    
    func nextOccurrence(for weekdays: Set<Weekday>) -> Date? {
        guard !weekdays.isEmpty else { return nil }
        
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.component(.weekday, from: now)
        
        let timeComponents = calendar.dateComponents([.hour, .minute], from: self)
        
        for day in 0..<7 {
            let targetDay = (today + day - 1) % 7 + 1
            let targetWeekday = calendarWeekdayToWeekday(targetDay)
            
            if weekdays.contains(targetWeekday) {
                var dateComponents = calendar.dateComponents([.year, .month, .day], from: now)
                dateComponents.hour = timeComponents.hour
                dateComponents.minute = timeComponents.minute
                dateComponents.second = 0
                
                if let targetDate = calendar.date(from: dateComponents) {
                    let adjustedDate = calendar.date(byAdding: .day, value: day, to: targetDate) ?? targetDate
                    
                    if day == 0 && adjustedDate <= now {
                        continue
                    }
                    
                    return adjustedDate
                }
            }
        }
        
        return nil
    }
    
    func nextOccurrenceOneTime() -> Date? {
        let now = Date()
        if self > now {
            return self
        } else {
            return Calendar.current.date(byAdding: .day, value: 1, to: self)
        }
    }
    
    func isToday() -> Bool {
        return Calendar.current.isDateInToday(self)
    }
    
    func isTomorrow() -> Bool {
        return Calendar.current.isDateInTomorrow(self)
    }
    
    func timeUntilAlarm() -> String {
        let now = Date()
        let timeInterval = self.timeIntervalSince(now)
        
        if timeInterval <= 0 {
            return "Past due"
        }
        
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) / 60 % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func calendarWeekdayToWeekday(_ calendarWeekday: Int) -> Weekday {
        switch calendarWeekday {
        case 1: return .sunday
        case 2: return .monday
        case 3: return .tuesday
        case 4: return .wednesday
        case 5: return .thursday
        case 6: return .friday
        case 7: return .saturday
        default: return .monday
        }
    }
}