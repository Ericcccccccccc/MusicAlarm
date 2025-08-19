import SwiftUI

struct AlarmRowView: View {
    @Binding var alarm: Alarm
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(timeString)
                        .font(.largeTitle)
                        .fontWeight(.thin)
                        .foregroundColor(alarm.isEnabled ? .textPrimary : .textSecondary)
                    
                    Text(amPmString)
                        .font(.title3)
                        .foregroundColor(alarm.isEnabled ? .textSecondary : .textTertiary)
                }
                
                Text(alarm.label)
                    .font(.headline)
                    .foregroundColor(alarm.isEnabled ? .textPrimary : .textSecondary)
                
                HStack {
                    if !alarm.repeatDays.isEmpty {
                        Text(repeatDaysString)
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                    
                    if let songId = alarm.spotifySongId,
                       let song = mockSongForId(songId) {
                        Text("♪ \(song.title)")
                            .font(.caption)
                            .foregroundColor(.spotifyGreen)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            Toggle("", isOn: $alarm.isEnabled)
                .labelsHidden()
        }
        .padding(.vertical, 8)
        .opacity(alarm.isEnabled ? 1.0 : 0.6)
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter.string(from: alarm.time)
    }
    
    private var amPmString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "a"
        return formatter.string(from: alarm.time)
    }
    
    private var repeatDaysString: String {
        if alarm.repeatDays.count == 7 {
            return "Every day"
        } else if alarm.repeatDays.count == 5 && 
                  alarm.repeatDays.contains(.monday) &&
                  alarm.repeatDays.contains(.tuesday) &&
                  alarm.repeatDays.contains(.wednesday) &&
                  alarm.repeatDays.contains(.thursday) &&
                  alarm.repeatDays.contains(.friday) {
            return "Weekdays"
        } else if alarm.repeatDays.count == 2 &&
                  alarm.repeatDays.contains(.saturday) &&
                  alarm.repeatDays.contains(.sunday) {
            return "Weekends"
        } else {
            return alarm.repeatDays.map { $0.rawValue }.joined(separator: " ")
        }
    }
    
    private func mockSongForId(_ id: String) -> SpotifySong? {
        let mockSongs = [
            SpotifySong(id: "1", title: "Wake Me Up", artist: "Avicii", albumArt: nil, uri: "spotify:track:4uLU6hMCjMI75M1A2tKUQC", previewURL: nil, durationMs: 243000),
            SpotifySong(id: "2", title: "Good Morning", artist: "John Legend", albumArt: nil, uri: "spotify:track:2Fxmhks0bxGSBdJ92vM42m", previewURL: nil, durationMs: 217000),
            SpotifySong(id: "3", title: "Eye of the Tiger", artist: "Survivor", albumArt: nil, uri: "spotify:track:2takcwOaAZWiXQijPHIx7B", previewURL: nil, durationMs: 245000),
            SpotifySong(id: "4", title: "Here Comes the Sun", artist: "The Beatles", albumArt: nil, uri: "spotify:track:6dGnYIeXmHdcikdzNNDMm2", previewURL: nil, durationMs: 185000),
            SpotifySong(id: "5", title: "Walking on Sunshine", artist: "Katrina and the Waves", albumArt: nil, uri: "spotify:track:05wIrZSwuaVWhcv5FfqeH0", previewURL: nil, durationMs: 236000)
        ]
        
        return mockSongs.first { $0.id == id }
    }
}

#Preview {
    List {
        AlarmRowView(alarm: .constant(Alarm(
            time: Calendar.current.date(bySettingHour: 7, minute: 30, second: 0, of: Date()) ?? Date(),
            isEnabled: true,
            repeatDays: [.monday, .tuesday, .wednesday, .thursday, .friday],
            spotifySongId: "1",
            label: "Morning Alarm"
        )))
        
        AlarmRowView(alarm: .constant(Alarm(
            time: Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: Date()) ?? Date(),
            isEnabled: false,
            repeatDays: [],
            spotifySongId: nil,
            label: "Bedtime"
        )))
    }
}