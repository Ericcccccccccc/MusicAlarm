import SwiftUI

struct AlarmListView: View {
    @StateObject private var viewModel = AlarmListViewModel()
    @State private var showingAddAlarm = false
    @State private var selectedAlarm: Alarm?
    
    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()
            
            if viewModel.alarms.isEmpty {
                emptyStateView
            } else {
                alarmListView
            }
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    addAlarmButton
                }
            }
            .padding()
        }
        .navigationTitle("Alarms")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingAddAlarm) {
            NavigationStack {
                AddEditAlarmView(alarm: nil) { alarm in
                    viewModel.addAlarm(alarm)
                }
            }
        }
        .sheet(item: $selectedAlarm) { alarm in
            NavigationStack {
                AddEditAlarmView(alarm: alarm) { editedAlarm in
                    viewModel.updateAlarm(editedAlarm)
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "alarm")
                .font(.system(size: 80))
                .foregroundColor(.appSecondary)
            
            Text("No Alarms")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.textPrimary)
            
            Text("Tap the + button to add your first alarm")
                .font(.body)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
    
    private var alarmListView: some View {
        List {
            ForEach($viewModel.alarms) { $alarm in
                AlarmRowView(alarm: $alarm)
                    .listRowBackground(Color.appBackground)
                    .onTapGesture {
                        selectedAlarm = alarm
                    }
            }
            .onDelete(perform: viewModel.deleteAlarms)
        }
        .listStyle(.plain)
        .refreshable {
            viewModel.loadAlarms()
        }
    }
    
    private var addAlarmButton: some View {
        Button(action: {
            showingAddAlarm = true
        }) {
            Image(systemName: "plus")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(Color.appPrimary)
                .clipShape(Circle())
                .shadow(radius: 4, y: 2)
        }
        .accessibility(label: Text("Add new alarm"))
    }
}

#Preview {
    NavigationStack {
        AlarmListView()
    }
}