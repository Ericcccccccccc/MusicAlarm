import Foundation
import SwiftUI

@MainActor
class AddEditAlarmViewModel: ObservableObject {
    @Published var time: Date
    @Published var isEnabled: Bool
    @Published var repeatDays: Set<Weekday>
    @Published var selectedSongId: String?
    @Published var selectedSong: SpotifySong?
    @Published var label: String
    @Published var snoozeEnabled: Bool
    @Published var soundVolume: Float
    
    @Published var showingSpotifySearch = false
    
    private let originalAlarm: Alarm?
    private let isEditing: Bool
    
    var navigationTitle: String {
        isEditing ? "Edit Alarm" : "Add Alarm"
    }
    
    var saveButtonTitle: String {
        isEditing ? "Save" : "Add"
    }
    
    init(alarm: Alarm? = nil) {
        self.originalAlarm = alarm
        self.isEditing = alarm != nil
        
        if let alarm = alarm {
            self.time = alarm.time
            self.isEnabled = alarm.isEnabled
            self.repeatDays = alarm.repeatDays
            self.selectedSongId = alarm.spotifySongId
            self.label = alarm.label
            self.snoozeEnabled = alarm.snoozeEnabled
            self.soundVolume = alarm.soundVolume
            
            if let songId = alarm.spotifySongId {
                self.selectedSong = mockSongForId(songId)
            }
        } else {
            let now = Date()
            let calendar = Calendar.current
            let nextHour = calendar.date(byAdding: .hour, value: 1, to: now) ?? now
            let roundedTime = calendar.date(bySettingMinute: 0, second: 0, of: nextHour) ?? now
            
            self.time = roundedTime
            self.isEnabled = true
            self.repeatDays = []
            self.selectedSongId = nil
            self.selectedSong = nil
            self.label = "Alarm"
            self.snoozeEnabled = true
            self.soundVolume = 0.8
        }
    }
    
    func createOrUpdateAlarm() -> Alarm {
        return Alarm(
            time: time,
            isEnabled: isEnabled,
            repeatDays: repeatDays,
            spotifySongId: selectedSongId,
            label: label,
            snoozeEnabled: snoozeEnabled,
            soundVolume: soundVolume
        )
    }
    
    func selectSong(_ song: SpotifySong) {
        selectedSong = song
        selectedSongId = song.id
        showingSpotifySearch = false
    }
    
    func removeSong() {
        selectedSong = nil
        selectedSongId = nil
    }
    
    var hasChanges: Bool {
        guard let original = originalAlarm else { return true }
        
        return time != original.time ||
               isEnabled != original.isEnabled ||
               repeatDays != original.repeatDays ||
               selectedSongId != original.spotifySongId ||
               label != original.label ||
               snoozeEnabled != original.snoozeEnabled ||
               abs(soundVolume - original.soundVolume) > 0.001
    }
    
    private func mockSongForId(_ id: String) -> SpotifySong? {
        let mockSongs = [
            SpotifySong(id: "1", title: "Wake Me Up", artist: "Avicii", albumArt: nil, uri: "spotify:track:1", previewURL: nil, durationMs: 240000),
            SpotifySong(id: "2", title: "Good Morning", artist: "John Legend", albumArt: nil, uri: "spotify:track:2", previewURL: nil, durationMs: 180000),
            SpotifySong(id: "3", title: "Eye of the Tiger", artist: "Survivor", albumArt: nil, uri: "spotify:track:3", previewURL: nil, durationMs: 245000),
            SpotifySong(id: "4", title: "Here Comes the Sun", artist: "The Beatles", albumArt: nil, uri: "spotify:track:4", previewURL: nil, durationMs: 185000),
            SpotifySong(id: "5", title: "Walking on Sunshine", artist: "Katrina and the Waves", albumArt: nil, uri: "spotify:track:5", previewURL: nil, durationMs: 238000)
        ]
        
        return mockSongs.first { $0.id == id }
    }
}