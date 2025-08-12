import Foundation

class SpotifyAPIClient {
    
    static let shared = SpotifyAPIClient()
    
    private let networkManager = NetworkManager.shared
    private let authManager = SpotifyAuthManager.shared
    
    private init() {}
    
    // MARK: - Search Methods
    
    func searchTracks(query: String, limit: Int = SpotifyConfig.defaultLimit, offset: Int = 0) async throws -> [SpotifyTrack] {
        let accessToken = try await authManager.getValidAccessToken()
        
        let endpoint = SpotifyConfig.APIEndpoint.search(
            query: query,
            type: "track",
            limit: min(limit, SpotifyConfig.maxLimit),
            offset: offset
        )
        
        guard let request = networkManager.buildSpotifyAPIRequest(
            endpoint: endpoint,
            accessToken: accessToken
        ) else {
            throw SpotifyAPIError.invalidResponse
        }
        
        do {
            let response = try await networkManager.performRequest(
                request,
                responseType: SpotifySearchResponse.self
            )
            return response.tracks?.items ?? []
        } catch {
            throw networkManager.handleNetworkError(error)
        }
    }
    
    func searchAll(query: String, limit: Int = SpotifyConfig.defaultLimit, offset: Int = 0) async throws -> SpotifySearchResponse {
        let accessToken = try await authManager.getValidAccessToken()
        
        let endpoint = SpotifyConfig.APIEndpoint.search(
            query: query,
            type: "album,artist,playlist,track",
            limit: min(limit, SpotifyConfig.maxLimit),
            offset: offset
        )
        
        guard let request = networkManager.buildSpotifyAPIRequest(
            endpoint: endpoint,
            accessToken: accessToken
        ) else {
            throw SpotifyAPIError.invalidResponse
        }
        
        do {
            let response = try await networkManager.performRequest(
                request,
                responseType: SpotifySearchResponse.self
            )
            return response
        } catch {
            throw networkManager.handleNetworkError(error)
        }
    }
    
    // MARK: - Track Methods
    
    func getTrack(id: String) async throws -> SpotifyTrack {
        let accessToken = try await authManager.getValidAccessToken()
        
        let endpoint = SpotifyConfig.APIEndpoint.track(id: id)
        
        guard let request = networkManager.buildSpotifyAPIRequest(
            endpoint: endpoint,
            accessToken: accessToken
        ) else {
            throw SpotifyAPIError.invalidResponse
        }
        
        do {
            let track = try await networkManager.performRequest(
                request,
                responseType: SpotifyTrack.self
            )
            return track
        } catch {
            throw networkManager.handleNetworkError(error)
        }
    }
    
    func getTracks(ids: [String]) async throws -> [SpotifyTrack] {
        guard !ids.isEmpty else { return [] }
        
        let accessToken = try await authManager.getValidAccessToken()
        
        let idsString = ids.prefix(50).joined(separator: ",")
        
        guard let url = URL(string: "\(SpotifyConfig.apiBaseURL)/tracks?ids=\(idsString)") else {
            throw SpotifyAPIError.invalidResponse
        }
        
        let request = networkManager.buildGETRequest(
            url: url,
            headers: ["Authorization": "Bearer \(accessToken)"]
        )
        
        do {
            let response = try await networkManager.performRequest(
                request,
                responseType: SpotifyTracksContainer.self
            )
            return response.tracks
        } catch {
            throw networkManager.handleNetworkError(error)
        }
    }
    
    // MARK: - Playlist Methods
    
    func getUserPlaylists(limit: Int = SpotifyConfig.defaultLimit, offset: Int = 0) async throws -> [SpotifyPlaylist] {
        let accessToken = try await authManager.getValidAccessToken()
        
        let endpoint = SpotifyConfig.APIEndpoint.userPlaylists(
            limit: min(limit, SpotifyConfig.maxLimit),
            offset: offset
        )
        
        guard let request = networkManager.buildSpotifyAPIRequest(
            endpoint: endpoint,
            accessToken: accessToken
        ) else {
            throw SpotifyAPIError.invalidResponse
        }
        
        do {
            let response = try await networkManager.performRequest(
                request,
                responseType: SpotifyPlaylistsResponse.self
            )
            return response.items
        } catch {
            throw networkManager.handleNetworkError(error)
        }
    }
    
    func getPlaylistTracks(playlistId: String, limit: Int = SpotifyConfig.defaultLimit, offset: Int = 0) async throws -> [SpotifyTrack] {
        let accessToken = try await authManager.getValidAccessToken()
        
        let endpoint = SpotifyConfig.APIEndpoint.playlistTracks(
            playlistId: playlistId,
            limit: min(limit, SpotifyConfig.maxLimit),
            offset: offset
        )
        
        guard let request = networkManager.buildSpotifyAPIRequest(
            endpoint: endpoint,
            accessToken: accessToken
        ) else {
            throw SpotifyAPIError.invalidResponse
        }
        
        do {
            let response = try await networkManager.performRequest(
                request,
                responseType: SpotifyPlaylistTracksResponse.self
            )
            return response.items.compactMap { $0.track }
        } catch {
            throw networkManager.handleNetworkError(error)
        }
    }
    
    // MARK: - User Methods
    
    func getCurrentUser() async throws -> SpotifyUser {
        let accessToken = try await authManager.getValidAccessToken()
        
        let endpoint = SpotifyConfig.APIEndpoint.userProfile
        
        guard let request = networkManager.buildSpotifyAPIRequest(
            endpoint: endpoint,
            accessToken: accessToken
        ) else {
            throw SpotifyAPIError.invalidResponse
        }
        
        do {
            let user = try await networkManager.performRequest(
                request,
                responseType: SpotifyUser.self
            )
            return user
        } catch {
            throw networkManager.handleNetworkError(error)
        }
    }
    
    func getCurrentlyPlayingTrack() async throws -> SpotifyTrack? {
        let accessToken = try await authManager.getValidAccessToken()
        
        let endpoint = SpotifyConfig.APIEndpoint.currentTrack
        
        guard let request = networkManager.buildSpotifyAPIRequest(
            endpoint: endpoint,
            accessToken: accessToken
        ) else {
            throw SpotifyAPIError.invalidResponse
        }
        
        do {
            let response = try await networkManager.performRequest(
                request,
                responseType: SpotifyCurrentlyPlayingResponse.self
            )
            return response.item
        } catch {
            if case SpotifyAPIError.notFound = error {
                return nil
            }
            throw networkManager.handleNetworkError(error)
        }
    }
    
    // MARK: - Utility Methods
    
    func convertSpotifyTrackToSong(_ track: SpotifyTrack) -> SpotifySong {
        let artistName = track.artists.first?.name ?? "Unknown Artist"
        let albumArt = track.album.images.first?.url
        
        return SpotifySong(
            id: track.id,
            title: track.name,
            artist: artistName,
            albumArt: albumArt,
            uri: track.uri,
            previewURL: track.previewURL,
            durationMs: track.durationMs
        )
    }
    
    func convertSpotifyTracksToSongs(_ tracks: [SpotifyTrack]) -> [SpotifySong] {
        return tracks.map { convertSpotifyTrackToSong($0) }
    }
}

// MARK: - Additional Models for API Responses

private struct SpotifyTracksContainer: Codable {
    let tracks: [SpotifyTrack]
}

private struct SpotifyPlaylistTracksResponse: Codable {
    let items: [SpotifyPlaylistTrackItem]
    let total: Int
    let limit: Int
    let offset: Int
    let next: String?
    let previous: String?
}

private struct SpotifyPlaylistTrackItem: Codable {
    let track: SpotifyTrack?
}

private struct SpotifyCurrentlyPlayingResponse: Codable {
    let item: SpotifyTrack?
    let isPlaying: Bool?
    let progressMs: Int?
    
    enum CodingKeys: String, CodingKey {
        case item
        case isPlaying = "is_playing"
        case progressMs = "progress_ms"
    }
}