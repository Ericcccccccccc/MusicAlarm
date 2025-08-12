import Foundation
import Combine

protocol SpotifyManagerProtocol: ObservableObject {
    
    // MARK: - Authentication State
    var isAuthenticated: Bool { get }
    var isAuthenticating: Bool { get }
    
    // MARK: - Authentication Methods
    func authenticate() async throws
    func logout()
    func checkAuthenticationStatus()
    
    // MARK: - Search Methods
    func searchTracks(query: String, limit: Int) async throws -> [SpotifySong]
    func searchAll(query: String, limit: Int) async throws -> SpotifySearchResult
    
    // MARK: - Track Methods
    func getTrack(id: String) async throws -> SpotifySong
    func getTracks(ids: [String]) async throws -> [SpotifySong]
    
    // MARK: - Playlist Methods
    func getUserPlaylists(limit: Int) async throws -> [SpotifyPlaylist]
    func getPlaylistTracks(playlistId: String, limit: Int) async throws -> [SpotifySong]
    
    // MARK: - User Methods
    func getCurrentUser() async throws -> SpotifyUser
    func getCurrentlyPlayingTrack() async throws -> SpotifySong?
}

// MARK: - Supporting Types for Protocol

struct SpotifySearchResult {
    let tracks: [SpotifySong]
    let albums: [SpotifyAlbum]
    let artists: [SpotifyArtist]
    let playlists: [SpotifyPlaylist]
}

// MARK: - Default Implementation Extensions

extension SpotifyManagerProtocol {
    
    func searchTracks(query: String) async throws -> [SpotifySong] {
        return try await searchTracks(query: query, limit: SpotifyConfig.defaultLimit)
    }
    
    func searchAll(query: String) async throws -> SpotifySearchResult {
        return try await searchAll(query: query, limit: SpotifyConfig.defaultLimit)
    }
    
    func getUserPlaylists() async throws -> [SpotifyPlaylist] {
        return try await getUserPlaylists(limit: SpotifyConfig.defaultLimit)
    }
    
    func getPlaylistTracks(playlistId: String) async throws -> [SpotifySong] {
        return try await getPlaylistTracks(playlistId: playlistId, limit: SpotifyConfig.defaultLimit)
    }
}

// MARK: - Additional Protocol for Advanced Features

protocol SpotifyPlaybackProtocol {
    
    // MARK: - Playback Control
    func play(uri: String) async throws
    func pause() async throws
    func resume() async throws
    func skipToNext() async throws
    func skipToPrevious() async throws
    
    // MARK: - Volume Control
    func setVolume(_ volume: Int) async throws
    
    // MARK: - Playback State
    func getPlaybackState() async throws -> SpotifyPlaybackState?
}

// MARK: - Playback State Model

struct SpotifyPlaybackState {
    let isPlaying: Bool
    let track: SpotifySong?
    let progressMs: Int
    let volume: Int
    let device: SpotifyDevice?
}

struct SpotifyDevice {
    let id: String
    let name: String
    let type: String
    let isActive: Bool
    let volumePercent: Int?
}