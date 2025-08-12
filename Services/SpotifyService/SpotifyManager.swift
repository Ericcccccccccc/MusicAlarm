import Foundation
import Combine

@MainActor
class SpotifyManager: SpotifyManagerProtocol {
    
    static let shared = SpotifyManager()
    
    private let authManager = SpotifyAuthManager.shared
    private let apiClient = SpotifyAPIClient.shared
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Published Properties
    
    @Published var isAuthenticated = false
    @Published var isAuthenticating = false
    
    // MARK: - Private Properties
    
    private var searchCache: [String: (result: SpotifySearchResult, timestamp: Date)] = [:]
    private let cacheExpirationInterval: TimeInterval = 300 // 5 minutes
    
    private init() {
        setupBindings()
        checkAuthenticationStatus()
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        authManager.$isAuthenticated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isAuthenticated in
                self?.isAuthenticated = isAuthenticated
            }
            .store(in: &cancellables)
        
        authManager.$isAuthenticating
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isAuthenticating in
                self?.isAuthenticating = isAuthenticating
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Authentication Methods
    
    func authenticate() async throws {
        _ = try await authManager.authenticate()
    }
    
    func logout() {
        authManager.logout()
        clearCache()
    }
    
    func checkAuthenticationStatus() {
        authManager.checkAuthenticationStatus()
    }
    
    // MARK: - Search Methods
    
    func searchTracks(query: String, limit: Int = SpotifyConfig.defaultLimit) async throws -> [SpotifySong] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }
        
        let tracks = try await apiClient.searchTracks(query: query, limit: limit)
        return apiClient.convertSpotifyTracksToSongs(tracks)
    }
    
    func searchAll(query: String, limit: Int = SpotifyConfig.defaultLimit) async throws -> SpotifySearchResult {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return SpotifySearchResult(tracks: [], albums: [], artists: [], playlists: [])
        }
        
        let cacheKey = "\(query)_\(limit)"
        
        if let cachedResult = getCachedSearchResult(for: cacheKey) {
            return cachedResult
        }
        
        let response = try await apiClient.searchAll(query: query, limit: limit)
        
        let result = SpotifySearchResult(
            tracks: apiClient.convertSpotifyTracksToSongs(response.tracks?.items ?? []),
            albums: response.albums?.items ?? [],
            artists: response.artists?.items ?? [],
            playlists: response.playlists?.items ?? []
        )
        
        cacheSearchResult(result, for: cacheKey)
        
        return result
    }
    
    // MARK: - Track Methods
    
    func getTrack(id: String) async throws -> SpotifySong {
        let track = try await apiClient.getTrack(id: id)
        return apiClient.convertSpotifyTrackToSong(track)
    }
    
    func getTracks(ids: [String]) async throws -> [SpotifySong] {
        guard !ids.isEmpty else { return [] }
        
        let tracks = try await apiClient.getTracks(ids: ids)
        return apiClient.convertSpotifyTracksToSongs(tracks)
    }
    
    // MARK: - Playlist Methods
    
    func getUserPlaylists(limit: Int = SpotifyConfig.defaultLimit) async throws -> [SpotifyPlaylist] {
        return try await apiClient.getUserPlaylists(limit: limit)
    }
    
    func getPlaylistTracks(playlistId: String, limit: Int = SpotifyConfig.defaultLimit) async throws -> [SpotifySong] {
        let tracks = try await apiClient.getPlaylistTracks(playlistId: playlistId, limit: limit)
        return apiClient.convertSpotifyTracksToSongs(tracks)
    }
    
    // MARK: - User Methods
    
    func getCurrentUser() async throws -> SpotifyUser {
        return try await apiClient.getCurrentUser()
    }
    
    func getCurrentlyPlayingTrack() async throws -> SpotifySong? {
        guard let track = try await apiClient.getCurrentlyPlayingTrack() else {
            return nil
        }
        return apiClient.convertSpotifyTrackToSong(track)
    }
    
    // MARK: - Cache Management
    
    private func getCachedSearchResult(for key: String) -> SpotifySearchResult? {
        guard let cached = searchCache[key] else { return nil }
        
        let now = Date()
        if now.timeIntervalSince(cached.timestamp) > cacheExpirationInterval {
            searchCache.removeValue(forKey: key)
            return nil
        }
        
        return cached.result
    }
    
    private func cacheSearchResult(_ result: SpotifySearchResult, for key: String) {
        searchCache[key] = (result: result, timestamp: Date())
        
        if searchCache.count > 50 {
            let oldestKey = searchCache.min { $0.value.timestamp < $1.value.timestamp }?.key
            if let keyToRemove = oldestKey {
                searchCache.removeValue(forKey: keyToRemove)
            }
        }
    }
    
    private func clearCache() {
        searchCache.removeAll()
    }
}

// MARK: - Error Handling Extensions

extension SpotifyManager {
    
    func handleError(_ error: Error) -> String {
        switch error {
        case SpotifyAuthError.invalidClientCredentials:
            return SpotifyConfig.ErrorMessages.invalidClientID
        case SpotifyAuthError.authorizationFailed:
            return SpotifyConfig.ErrorMessages.authenticationFailed
        case SpotifyAuthError.tokenRefreshFailed:
            return SpotifyConfig.ErrorMessages.tokenRefreshFailed
        case SpotifyAPIError.unauthorized:
            return SpotifyConfig.ErrorMessages.unauthorized
        case SpotifyAPIError.rateLimited:
            return SpotifyConfig.ErrorMessages.rateLimited
        case SpotifyAPIError.notFound:
            return SpotifyConfig.ErrorMessages.notFound
        case SpotifyAPIError.serverError:
            return SpotifyConfig.ErrorMessages.serverError
        case SpotifyAPIError.networkError(_):
            return SpotifyConfig.ErrorMessages.networkError
        default:
            return SpotifyConfig.ErrorMessages.invalidResponse
        }
    }
}

// MARK: - Convenience Methods

extension SpotifyManager {
    
    func searchTracksWithDetails(query: String, limit: Int = SpotifyConfig.defaultLimit) async throws -> (songs: [SpotifySong], hasMore: Bool) {
        let tracks = try await apiClient.searchTracks(query: query, limit: limit, offset: 0)
        let songs = apiClient.convertSpotifyTracksToSongs(tracks)
        let hasMore = tracks.count == limit
        
        return (songs: songs, hasMore: hasMore)
    }
    
    func loadMoreSearchResults(query: String, currentCount: Int, limit: Int = SpotifyConfig.defaultLimit) async throws -> [SpotifySong] {
        let tracks = try await apiClient.searchTracks(query: query, limit: limit, offset: currentCount)
        return apiClient.convertSpotifyTracksToSongs(tracks)
    }
    
    func getPlaylistTracksWithDetails(playlistId: String, limit: Int = SpotifyConfig.defaultLimit) async throws -> (songs: [SpotifySong], hasMore: Bool) {
        let tracks = try await apiClient.getPlaylistTracks(playlistId: playlistId, limit: limit, offset: 0)
        let songs = apiClient.convertSpotifyTracksToSongs(tracks)
        let hasMore = tracks.count == limit
        
        return (songs: songs, hasMore: hasMore)
    }
    
    func validateSpotifyURI(_ uri: String) -> Bool {
        return uri.hasPrefix("spotify:track:") || uri.hasPrefix("spotify:album:") || uri.hasPrefix("spotify:playlist:")
    }
    
    func extractSpotifyID(from uri: String) -> String? {
        let components = uri.components(separatedBy: ":")
        guard components.count >= 3, components[0] == "spotify" else {
            return nil
        }
        return components[2]
    }
}