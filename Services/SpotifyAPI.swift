import Foundation
import Combine

class SpotifyAPI: ObservableObject {
    static let shared = SpotifyAPI()
    
    @Published var isAuthenticated = false
    @Published var accessToken: String?
    
    private let clientId = "4d3403d77aee43e181e173c926ecc4d3"
    private let redirectUri = "musicalarm://callback"
    private let scopes = "user-read-private,streaming,user-library-read,playlist-read-private"
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadStoredToken()
    }
    
    // MARK: - Authentication
    
    func authenticate() {
        let authURL = buildAuthURL()
        if let url = URL(string: authURL) {
            UIApplication.shared.open(url)
        }
    }
    
    func handleCallback(url: URL) {
        guard let code = extractAuthorizationCode(from: url) else { return }
        exchangeCodeForToken(code: code)
    }
    
    private func buildAuthURL() -> String {
        let baseURL = "https://accounts.spotify.com/authorize"
        let parameters = [
            "client_id": clientId,
            "response_type": "code",
            "redirect_uri": redirectUri,
            "scope": scopes,
            "show_dialog": "true"
        ]
        
        let queryString = parameters
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")
        
        return "\(baseURL)?\(queryString)"
    }
    
    private func extractAuthorizationCode(from url: URL) -> String? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else { return nil }
        
        return queryItems.first(where: { $0.name == "code" })?.value
    }
    
    private func exchangeCodeForToken(code: String) {
        let url = URL(string: "https://accounts.spotify.com/api/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let parameters = [
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": redirectUri,
            "client_id": clientId,
            "client_secret": "c83e8081a91a40bcbc048f5305c543f9" // Replace with your client secret
        ]
        
        let bodyString = parameters
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
        
        request.httpBody = bodyString.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let data = data, error == nil else { return }
            
            if let tokenResponse = try? JSONDecoder().decode(TokenResponse.self, from: data) {
                DispatchQueue.main.async {
                    self?.accessToken = tokenResponse.accessToken
                    self?.isAuthenticated = true
                    self?.storeToken(tokenResponse.accessToken)
                }
            }
        }.resume()
    }
    
    // MARK: - API Calls
    
    func searchTracks(query: String) -> AnyPublisher<[SpotifyTrack], Error> {
        guard let token = accessToken else {
            return Fail(error: SpotifyError.notAuthenticated)
                .eraseToAnyPublisher()
        }
        
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://api.spotify.com/v1/search?q=\(encodedQuery)&type=track&limit=20"
        
        guard let url = URL(string: urlString) else {
            return Fail(error: SpotifyError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: SpotifySearchResponse.self, decoder: JSONDecoder())
            .map { $0.tracks.items }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func getUserPlaylists() -> AnyPublisher<[SpotifyPlaylist], Error> {
        guard let token = accessToken else {
            return Fail(error: SpotifyError.notAuthenticated)
                .eraseToAnyPublisher()
        }
        
        let url = URL(string: "https://api.spotify.com/v1/me/playlists?limit=50")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: SpotifyUserPlaylistsResponse.self, decoder: JSONDecoder())
            .map { $0.items }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Token Management
    
    private func storeToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: "spotify_access_token")
    }
    
    private func loadStoredToken() {
        if let token = UserDefaults.standard.string(forKey: "spotify_access_token") {
            accessToken = token
            isAuthenticated = true
        }
    }
    
    func logout() {
        accessToken = nil
        isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: "spotify_access_token")
    }
}

// MARK: - Supporting Types

struct TokenResponse: Codable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
    let refreshToken: String?
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
    }
}

enum SpotifyError: Error {
    case notAuthenticated
    case invalidURL
    case noData
}