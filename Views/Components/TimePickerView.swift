import SwiftUI

struct TimePickerView: View {
    @Binding var selectedTime: Date
    let title: String
    
    init(selectedTime: Binding<Date>, title: String = "Alarm Time") {
        self._selectedTime = selectedTime
        self.title = title
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            DatePicker(
                "Select Time",
                selection: $selectedTime,
                displayedComponents: [.hourAndMinute]
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .background(Color.appSecondaryBackground)
            .cornerRadius(12)
        }
    }
}

#Preview {
    VStack {
        TimePickerView(
            selectedTime: .constant(Calendar.current.date(bySettingHour: 7, minute: 30, second: 0, of: Date()) ?? Date())
        )
        .padding()
        
        Divider()
        
        TimePickerView(
            selectedTime: .constant(Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: Date()) ?? Date()),
            title: "Bedtime"
        )
        .padding()
    }
    .background(Color.appBackground)
}