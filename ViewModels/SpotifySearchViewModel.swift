import Foundation
import SwiftUI

@MainActor
class SpotifySearchViewModel: ObservableObject {
    @Published var searchQuery: String = ""
    @Published var searchResults: [SpotifySong] = []
    @Published var isLoading: Bool = false
    @Published var hasSearched: Bool = false
    
    private var spotifyManager: SpotifyManagerProtocol?
    private var searchTask: Task<Void, Never>?
    
    init(spotifyManager: SpotifyManagerProtocol? = nil) {
        self.spotifyManager = spotifyManager
    }
    
    func searchSongs() {
        guard !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = []
            hasSearched = false
            return
        }
        
        searchTask?.cancel()
        searchTask = Task {
            isLoading = true
            hasSearched = true
            
            do {
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay for realistic feel
                
                if !Task.isCancelled {
                    if let manager = spotifyManager {
                        do {
                            searchResults = try await manager.searchTracks(query: searchQuery, limit: 20)
                        } catch {
                            print("Search error: \(error)")
                            searchResults = []
                        }
                    } else {
                        searchResults = mockSearchResults(for: searchQuery)
                    }
                }
            } catch {
                // Handle task cancellation gracefully
            }
            
            if !Task.isCancelled {
                isLoading = false
            }
        }
    }
    
    func selectSong(_ song: SpotifySong) {
        // Song selection will be handled by the parent view
        // This is just a placeholder for future Spotify integration
        print("Selected song: \(song.title) by \(song.artist)")
    }
    
    func clearSearch() {
        searchQuery = ""
        searchResults = []
        hasSearched = false
        searchTask?.cancel()
    }
    
    private func mockSearchResults(for query: String) -> [SpotifySong] {
        let allMockSongs = [
            SpotifySong(id: "1", title: "Wake Me Up", artist: "Avicii", albumArt: nil, uri: "spotify:track:1", previewURL: nil, durationMs: 240000),
            SpotifySong(id: "2", title: "Good Morning", artist: "John Legend", albumArt: nil, uri: "spotify:track:2", previewURL: nil, durationMs: 180000),
            SpotifySong(id: "3", title: "Eye of the Tiger", artist: "Survivor", albumArt: nil, uri: "spotify:track:3", previewURL: nil, durationMs: 245000),
            SpotifySong(id: "4", title: "Here Comes the Sun", artist: "The Beatles", albumArt: nil, uri: "spotify:track:4", previewURL: nil, durationMs: 185000),
            SpotifySong(id: "5", title: "Walking on Sunshine", artist: "Katrina and the Waves", albumArt: nil, uri: "spotify:track:5", previewURL: nil, durationMs: 238000),
            SpotifySong(id: "6", title: "Happy", artist: "Pharrell Williams", albumArt: nil, uri: "spotify:track:6", previewURL: nil, durationMs: 233000),
            SpotifySong(id: "7", title: "Can't Stop the Feeling!", artist: "Justin Timberlake", albumArt: nil, uri: "spotify:track:7", previewURL: nil, durationMs: 236000),
            SpotifySong(id: "8", title: "Uptown Funk", artist: "Mark Ronson ft. Bruno Mars", albumArt: nil, uri: "spotify:track:8", previewURL: nil, durationMs: 270000),
            SpotifySong(id: "9", title: "Shake It Off", artist: "Taylor Swift", albumArt: nil, uri: "spotify:track:9", previewURL: nil, durationMs: 219000),
            SpotifySong(id: "10", title: "Don't Stop Believin'", artist: "Journey", albumArt: nil, uri: "spotify:track:10", previewURL: nil, durationMs: 251000),
            SpotifySong(id: "11", title: "Good Vibrations", artist: "The Beach Boys", albumArt: nil, uri: "spotify:track:11", previewURL: nil, durationMs: 195000),
            SpotifySong(id: "12", title: "Mr. Blue Sky", artist: "Electric Light Orchestra", albumArt: nil, uri: "spotify:track:12", previewURL: nil, durationMs: 303000),
            SpotifySong(id: "13", title: "I Want to Wake Up", artist: "Pet Shop Boys", albumArt: nil, uri: "spotify:track:13", previewURL: nil, durationMs: 258000),
            SpotifySong(id: "14", title: "Morning Glory", artist: "Oasis", albumArt: nil, uri: "spotify:track:14", previewURL: nil, durationMs: 303000),
            SpotifySong(id: "15", title: "Sunrise", artist: "Norah Jones", albumArt: nil, uri: "spotify:track:15", previewURL: nil, durationMs: 201000),
            SpotifySong(id: "16", title: "Beautiful Day", artist: "U2", albumArt: nil, uri: "spotify:track:16", previewURL: nil, durationMs: 248000),
            SpotifySong(id: "17", title: "Good Day Sunshine", artist: "The Beatles", albumArt: nil, uri: "spotify:track:17", previewURL: nil, durationMs: 129000),
            SpotifySong(id: "18", title: "Wake Up", artist: "Arcade Fire", albumArt: nil, uri: "spotify:track:18", previewURL: nil, durationMs: 335000),
            SpotifySong(id: "19", title: "Morning Has Broken", artist: "Cat Stevens", albumArt: nil, uri: "spotify:track:19", previewURL: nil, durationMs: 198000),
            SpotifySong(id: "20", title: "Rise and Shine", artist: "Kygo", albumArt: nil, uri: "spotify:track:20", previewURL: nil, durationMs: 232000)
        ]
        
        let lowercaseQuery = query.lowercased()
        let filteredSongs = allMockSongs.filter { song in
            song.title.lowercased().contains(lowercaseQuery) ||
            song.artist.lowercased().contains(lowercaseQuery)
        }
        
        return Array(filteredSongs.prefix(10))
    }
}

extension SpotifySearchViewModel {
    var showEmptyState: Bool {
        hasSearched && searchResults.isEmpty && !isLoading
    }
    
    var showResults: Bool {
        !searchResults.isEmpty && !isLoading
    }
}