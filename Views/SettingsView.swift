import SwiftUI

struct SettingsView: View {
    @State private var notificationsEnabled = true
    @State private var defaultSnoozeEnabled = true
    @State private var defaultVolume: Float = 0.8
    @State private var defaultSnoozeDuration = 9
    
    private let snoozeDurationOptions = [5, 9, 10, 15, 20]
    
    var body: some View {
        NavigationStack {
            List {
                generalSection
                
                alarmDefaultsSection
                
                aboutSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Sections
    
    private var generalSection: some View {
        Section("General") {
            HStack {
                Label("Notifications", systemImage: "bell")
                Spacer()
                Toggle("", isOn: $notificationsEnabled)
                    .labelsHidden()
            }
            
            HStack {
                Label("Spotify Integration", systemImage: "music.note")
                Spacer()
                Text("Connected")
                    .foregroundColor(.spotifyGreen)
                    .font(.caption)
            }
        }
    }
    
    private var alarmDefaultsSection: some View {
        Section("Alarm Defaults") {
            HStack {
                Label("Snooze", systemImage: "clock.arrow.circlepath")
                Spacer()
                Toggle("", isOn: $defaultSnoozeEnabled)
                    .labelsHidden()
            }
            
            if defaultSnoozeEnabled {
                HStack {
                    Label("Snooze Duration", systemImage: "timer")
                    Spacer()
                    Picker("Snooze Duration", selection: $defaultSnoozeDuration) {
                        ForEach(snoozeDurationOptions, id: \.self) { duration in
                            Text("\(duration) min")
                                .tag(duration)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Label("Default Volume", systemImage: "speaker.wave.2")
                
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "speaker.fill")
                            .foregroundColor(.textSecondary)
                            .font(.caption)
                        
                        Slider(
                            value: $defaultVolume,
                            in: 0...1,
                            step: 0.01
                        )
                        .tint(.appPrimary)
                        
                        Image(systemName: "speaker.wave.3.fill")
                            .foregroundColor(.textSecondary)
                            .font(.caption)
                    }
                    
                    HStack {
                        Text("\(Int(defaultVolume * 100))%")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                            .monospacedDigit()
                        Spacer()
                    }
                }
                .padding(.leading, 24)
            }
        }
    }
    
    private var aboutSection: some View {
        Section("About") {
            HStack {
                Label("Version", systemImage: "info.circle")
                Spacer()
                Text("1.0.0")
                    .foregroundColor(.textSecondary)
            }
            
            HStack {
                Label("Privacy Policy", systemImage: "hand.raised")
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.textTertiary)
                    .font(.caption)
            }
            
            HStack {
                Label("Terms of Service", systemImage: "doc.text")
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.textTertiary)
                    .font(.caption)
            }
            
            HStack {
                Label("Support", systemImage: "questionmark.circle")
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.textTertiary)
                    .font(.caption)
            }
        }
    }
}

#Preview {
    SettingsView()
}