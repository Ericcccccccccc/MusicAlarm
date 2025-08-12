import SwiftUI

struct RepeatDaysSelector: View {
    @Binding var selectedDays: Set<Weekday>
    let title: String
    
    init(selectedDays: Binding<Set<Weekday>>, title: String = "Repeat") {
        self._selectedDays = selectedDays
        self.title = title
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            VStack(spacing: 12) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                    ForEach(Weekday.allCases, id: \.self) { day in
                        dayButton(for: day)
                    }
                }
                
                if !selectedDays.isEmpty {
                    summaryText
                        .padding(.top, 8)
                }
            }
            .padding()
            .background(Color.appSecondaryBackground)
            .cornerRadius(12)
        }
    }
    
    private func dayButton(for day: Weekday) -> some View {
        Button(action: {
            toggleDay(day)
        }) {
            Text(day.rawValue)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(selectedDays.contains(day) ? .white : .textPrimary)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(selectedDays.contains(day) ? Color.appPrimary : Color.appTertiary)
                )
                .overlay(
                    Circle()
                        .stroke(Color.appPrimary, lineWidth: selectedDays.contains(day) ? 0 : 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var summaryText: some View {
        Text(repeatSummary)
            .font(.caption)
            .foregroundColor(.textSecondary)
            .multilineTextAlignment(.center)
    }
    
    private func toggleDay(_ day: Weekday) {
        if selectedDays.contains(day) {
            selectedDays.remove(day)
        } else {
            selectedDays.insert(day)
        }
    }
    
    private var repeatSummary: String {
        if selectedDays.isEmpty {
            return "Never repeats"
        } else if selectedDays.count == 7 {
            return "Every day"
        } else if selectedDays.count == 5 && weekdaysSelected {
            return "Every weekday (Monday to Friday)"
        } else if selectedDays.count == 2 && weekendsSelected {
            return "Weekends (Saturday and Sunday)"
        } else {
            let sortedDays = Weekday.allCases.filter { selectedDays.contains($0) }
            return "Every " + sortedDays.map { $0.fullName }.joined(separator: ", ")
        }
    }
    
    private var weekdaysSelected: Bool {
        let weekdays: Set<Weekday> = [.monday, .tuesday, .wednesday, .thursday, .friday]
        return selectedDays == weekdays
    }
    
    private var weekendsSelected: Bool {
        let weekends: Set<Weekday> = [.saturday, .sunday]
        return selectedDays == weekends
    }
}

#Preview {
    VStack(spacing: 32) {
        RepeatDaysSelector(selectedDays: .constant([]))
        
        RepeatDaysSelector(selectedDays: .constant([.monday, .tuesday, .wednesday, .thursday, .friday]))
        
        RepeatDaysSelector(selectedDays: .constant([.saturday, .sunday]))
        
        RepeatDaysSelector(selectedDays: .constant(Set(Weekday.allCases)))
    }
    .padding()
    .background(Color.appBackground)
}