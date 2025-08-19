import SwiftUI

struct AddEditAlarmView: View {
    @StateObject private var viewModel: AddEditAlarmViewModel
    @Environment(\.dismiss) private var dismiss
    
    let onSave: (Alarm) -> Void
    
    init(alarm: Alarm? = nil, onSave: @escaping (Alarm) -> Void) {
        self._viewModel = StateObject(wrappedValue: AddEditAlarmViewModel(alarm: alarm))
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    alarmLabelSection
                    
                    timePickerSection
                    
                    repeatDaysSection
                    
                    songSelectionSection
                    
                    volumeSection
                    
                    snoozeSection
                }
                .padding()
            }
            .background(Color.appBackground)
            .navigationTitle(viewModel.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    cancelButton
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    saveButton
                }
            }
            .sheet(isPresented: $viewModel.showingSpotifySearch) {
                NavigationStack {
                    SpotifySearchView(onSongSelected: viewModel.selectSong)
                }
            }
        }
    }
    
    // MARK: - Sections
    
    private var alarmLabelSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Label")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            TextField("Alarm", text: $viewModel.label)
                .textFieldStyle(.roundedBorder)
                .background(Color.appSecondaryBackground)
        }
    }
    
    private var timePickerSection: some View {
        TimePickerView(selectedTime: $viewModel.time)
    }
    
    private var repeatDaysSection: some View {
        RepeatDaysSelector(selectedDays: $viewModel.repeatDays)
    }
    
    private var songSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Alarm Sound")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            VStack(spacing: 12) {
                if let selectedSong = viewModel.selectedSong {
                    selectedSongView(selectedSong)
                } else {
                    noSongSelectedView
                }
                
                chooseSongButton
            }
            .padding()
            .background(Color.appSecondaryBackground)
            .cornerRadius(12)
        }
    }
    
    private func selectedSongView(_ song: SpotifySong) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                
                Text(song.artist)
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                
                Text("Track")
                    .font(.caption)
                    .foregroundColor(.textTertiary)
            }
            
            Spacer()
            
            Button("Remove") {
                viewModel.removeSong()
            }
            .foregroundColor(.appDestructive)
            .font(.caption)
        }
        .padding(.vertical, 8)
    }
    
    private var noSongSelectedView: some View {
        HStack {
            Image(systemName: "music.note")
                .foregroundColor(.textSecondary)
                .font(.title2)
            
            Text("No song selected")
                .font(.subheadline)
                .foregroundColor(.textSecondary)
            
            Spacer()
        }
        .padding(.vertical, 16)
    }
    
    private var chooseSongButton: some View {
        Button(action: {
            viewModel.showingSpotifySearch = true
        }) {
            HStack {
                Image(systemName: "magnifyingglass")
                Text("Choose Song")
            }
            .foregroundColor(.spotifyGreen)
            .font(.headline)
        }
    }
    
    private var volumeSection: some View {
        VolumeSlider(volume: $viewModel.soundVolume, title: "Alarm Volume")
    }
    
    private var snoozeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Options")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            HStack {
                Toggle("Snooze", isOn: $viewModel.snoozeEnabled)
                    .font(.body)
            }
            .padding()
            .background(Color.appSecondaryBackground)
            .cornerRadius(12)
        }
    }
    
    // MARK: - Toolbar Buttons
    
    private var cancelButton: some View {
        Button("Cancel") {
            dismiss()
        }
        .foregroundColor(.textSecondary)
    }
    
    private var saveButton: some View {
        Button(viewModel.saveButtonTitle) {
            let alarm = viewModel.createOrUpdateAlarm()
            onSave(alarm)
            dismiss()
        }
        .foregroundColor(.appPrimary)
        .fontWeight(.semibold)
    }
}

#Preview {
    NavigationStack {
        AddEditAlarmView(alarm: nil) { _ in }
    }
}

#Preview("Edit Alarm") {
    NavigationStack {
        AddEditAlarmView(
            alarm: Alarm(
                time: Calendar.current.date(bySettingHour: 7, minute: 30, second: 0, of: Date()) ?? Date(),
                isEnabled: true,
                repeatDays: [.monday, .tuesday, .wednesday, .thursday, .friday],
                spotifySongId: "1",
                label: "Morning Alarm"
            )
        ) { _ in }
    }
}