import Foundation

struct SpotifySong: Codable, Identifiable, Equatable {
    let id: String
    let title: String
    let artist: String
    let albumArt: String?
    let uri: String
    let previewURL: String?
    let durationMs: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case title = "name"
        case artist
        case albumArt = "album_art"
        case uri
        case previewURL = "preview_url"
        case durationMs = "duration_ms"
    }
}

struct SpotifyTrack: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let uri: String
    let artists: [SpotifyArtist]
    let album: SpotifyAlbum
    let durationMs: Int
    let previewURL: String?
    let explicit: Bool
    let popularity: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case uri
        case artists
        case album
        case durationMs = "duration_ms"
        case previewURL = "preview_url"
        case explicit
        case popularity
    }
}

struct SpotifyArtist: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let uri: String
    let href: String?
    let images: [SpotifyImage]?
}

struct SpotifyAlbum: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let uri: String
    let images: [SpotifyImage]
    let releaseDate: String
    let totalTracks: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case uri
        case images
        case releaseDate = "release_date"
        case totalTracks = "total_tracks"
    }
}

struct SpotifyImage: Codable, Equatable {
    let url: String
    let height: Int?
    let width: Int?
}

struct SpotifyPlaylist: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let description: String?
    let uri: String
    let images: [SpotifyImage]
    let owner: SpotifyUser
    let tracks: SpotifyPlaylistTracks
    let isPublic: Bool
    let collaborative: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case uri
        case images
        case owner
        case tracks
        case isPublic = "public"
        case collaborative
    }
}

struct SpotifyUser: Codable, Identifiable, Equatable {
    let id: String
    let displayName: String?
    let images: [SpotifyImage]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case images
    }
}

struct SpotifyPlaylistTracks: Codable, Equatable {
    let href: String
    let total: Int
}

struct SpotifySearchResponse: Codable {
    let tracks: SpotifyTracksResponse?
    let albums: SpotifyAlbumsResponse?
    let artists: SpotifyArtistsResponse?
    let playlists: SpotifyPlaylistsResponse?
}

struct SpotifyTracksResponse: Codable {
    let href: String
    let items: [SpotifyTrack]
    let limit: Int
    let next: String?
    let offset: Int
    let previous: String?
    let total: Int
}

struct SpotifyAlbumsResponse: Codable {
    let href: String
    let items: [SpotifyAlbum]
    let limit: Int
    let next: String?
    let offset: Int
    let previous: String?
    let total: Int
}

struct SpotifyArtistsResponse: Codable {
    let href: String
    let items: [SpotifyArtist]
    let limit: Int
    let next: String?
    let offset: Int
    let previous: String?
    let total: Int
}

struct SpotifyPlaylistsResponse: Codable {
    let href: String
    let items: [SpotifyPlaylist]
    let limit: Int
    let next: String?
    let offset: Int
    let previous: String?
    let total: Int
}

struct SpotifyTokenResponse: Codable {
    let accessToken: String
    let tokenType: String
    let scope: String?
    let expiresIn: Int
    let refreshToken: String?
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case scope
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
    }
}

struct SpotifyError: Codable, Error {
    let error: SpotifyErrorDetail
}

struct SpotifyErrorDetail: Codable {
    let status: Int
    let message: String
}

enum SpotifyAuthError: Error {
    case invalidClientCredentials
    case authorizationFailed
    case tokenRefreshFailed
    case networkError(Error)
    case invalidResponse
}

enum SpotifyAPIError: Error {
    case unauthorized
    case rateLimited
    case notFound
    case badRequest
    case serverError
    case networkError(Error)
    case invalidResponse
}