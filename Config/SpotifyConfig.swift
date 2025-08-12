import Foundation

struct SpotifyConfig {
    // MARK: - Authentication Configuration
    static let clientID = "4d3403d77aee43e181e173c926ecc4d3"
    static let redirectURI = "musicalarm://spotify-auth"
    
    // MARK: - Spotify API Configuration
    static let authBaseURL = "https://accounts.spotify.com"
    static let apiBaseURL = "https://api.spotify.com/v1"
    
    // MARK: - Auth Endpoints
    static let authorizeURL = "\(authBaseURL)/authorize"
    static let tokenURL = "\(authBaseURL)/api/token"
    
    // MARK: - Scopes
    static let requiredScopes: [String] = [
        "streaming",
        "user-read-email",
        "user-read-private",
        "user-library-read",
        "user-library-modify",
        "user-read-playback-state",
        "user-modify-playback-state",
        "user-read-currently-playing",
        "playlist-read-private",
        "playlist-read-collaborative"
    ]
    
    static let scopeString = requiredScopes.joined(separator: " ")
    
    // MARK: - Keychain Keys
    static let accessTokenKey = "spotify_access_token"
    static let refreshTokenKey = "spotify_refresh_token"
    static let tokenExpirationKey = "spotify_token_expiration"
    
    // MARK: - Request Configuration
    static let defaultLimit = 20
    static let maxLimit = 50
    
    // MARK: - Cache Configuration
    static let tokenRefreshThreshold: TimeInterval = 300 // 5 minutes before expiry
    
    // MARK: - Helper Methods
    static func buildAuthorizeURL() -> URL? {
        var components = URLComponents(string: authorizeURL)
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "scope", value: scopeString),
            URLQueryItem(name: "state", value: generateState())
        ]
        return components?.url
    }
    
    static func isValidRedirectURL(_ url: URL) -> Bool {
        return url.scheme == "musicalarm" && url.host == "spotify-auth"
    }
    
    private static func generateState() -> String {
        return UUID().uuidString
    }
}

// MARK: - API Endpoints
extension SpotifyConfig {
    enum APIEndpoint {
        case search(query: String, type: String, limit: Int, offset: Int)
        case track(id: String)
        case userPlaylists(limit: Int, offset: Int)
        case playlistTracks(playlistId: String, limit: Int, offset: Int)
        case userProfile
        case currentTrack
        
        var path: String {
            switch self {
            case .search:
                return "/search"
            case .track(let id):
                return "/tracks/\(id)"
            case .userPlaylists:
                return "/me/playlists"
            case .playlistTracks(let playlistId, _, _):
                return "/playlists/\(playlistId)/tracks"
            case .userProfile:
                return "/me"
            case .currentTrack:
                return "/me/player/currently-playing"
            }
        }
        
        var queryItems: [URLQueryItem] {
            switch self {
            case .search(let query, let type, let limit, let offset):
                return [
                    URLQueryItem(name: "q", value: query),
                    URLQueryItem(name: "type", value: type),
                    URLQueryItem(name: "limit", value: "\(limit)"),
                    URLQueryItem(name: "offset", value: "\(offset)")
                ]
            case .userPlaylists(let limit, let offset),
                 .playlistTracks(_, let limit, let offset):
                return [
                    URLQueryItem(name: "limit", value: "\(limit)"),
                    URLQueryItem(name: "offset", value: "\(offset)")
                ]
            default:
                return []
            }
        }
        
        var url: URL? {
            var components = URLComponents(string: SpotifyConfig.apiBaseURL + path)
            if !queryItems.isEmpty {
                components?.queryItems = queryItems
            }
            return components?.url
        }
    }
}

// MARK: - Error Messages
extension SpotifyConfig {
    struct ErrorMessages {
        static let invalidClientID = "Invalid Spotify Client ID. Please configure your client ID in SpotifyConfig.swift"
        static let authenticationFailed = "Spotify authentication failed"
        static let tokenRefreshFailed = "Failed to refresh Spotify access token"
        static let networkError = "Network error occurred"
        static let invalidResponse = "Invalid response from Spotify API"
        static let unauthorized = "Unauthorized. Please re-authenticate with Spotify"
        static let rateLimited = "Rate limited. Please try again later"
        static let notFound = "Resource not found"
        static let serverError = "Spotify server error"
    }
}