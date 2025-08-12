import Foundation
import AuthenticationServices

class SpotifyAuthManager: NSObject, ObservableObject {
    
    static let shared = SpotifyAuthManager()
    
    private let networkManager = NetworkManager.shared
    private let keychainHelper = KeychainHelper.shared
    
    @Published var isAuthenticated = false
    @Published var isAuthenticating = false
    
    private var authSession: ASWebAuthenticationSession?
    
    override init() {
        super.init()
        checkAuthenticationStatus()
    }
    
    // MARK: - Authentication Status
    
    func checkAuthenticationStatus() {
        isAuthenticated = keychainHelper.isAccessTokenValid() || keychainHelper.hasValidRefreshToken()
    }
    
    // MARK: - Authentication Flow
    
    func authenticate() async throws -> String {
        guard SpotifyConfig.clientID != "YOUR_SPOTIFY_CLIENT_ID" else {
            throw SpotifyAuthError.invalidClientCredentials
        }
        
        await MainActor.run {
            isAuthenticating = true
        }
        
        defer {
            Task { @MainActor in
                isAuthenticating = false
            }
        }
        
        if keychainHelper.isAccessTokenValid() {
            if let accessToken = keychainHelper.getAccessToken() {
                await MainActor.run {
                    isAuthenticated = true
                }
                return accessToken
            }
        }
        
        if keychainHelper.hasValidRefreshToken() {
            do {
                let accessToken = try await refreshToken()
                await MainActor.run {
                    isAuthenticated = true
                }
                return accessToken
            } catch {
                print("Token refresh failed, starting new auth flow: \(error)")
            }
        }
        
        let authCode = try await performAuthorizationCodeFlow()
        let tokenResponse = try await exchangeCodeForToken(authCode)
        
        try saveTokenResponse(tokenResponse)
        
        await MainActor.run {
            isAuthenticated = true
        }
        
        return tokenResponse.accessToken
    }
    
    // MARK: - Authorization Code Flow
    
    private func performAuthorizationCodeFlow() async throws -> String {
        guard let authURL = SpotifyConfig.buildAuthorizeURL() else {
            throw SpotifyAuthError.invalidClientCredentials
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                self.authSession = ASWebAuthenticationSession(
                    url: authURL,
                    callbackURLScheme: "musicalarm"
                ) { callbackURL, error in
                    if let error = error {
                        continuation.resume(throwing: SpotifyAuthError.authorizationFailed)
                        return
                    }
                    
                    guard let callbackURL = callbackURL,
                          SpotifyConfig.isValidRedirectURL(callbackURL) else {
                        continuation.resume(throwing: SpotifyAuthError.authorizationFailed)
                        return
                    }
                    
                    let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)
                    
                    if let error = components?.queryItems?.first(where: { $0.name == "error" })?.value {
                        print("Auth error: \(error)")
                        continuation.resume(throwing: SpotifyAuthError.authorizationFailed)
                        return
                    }
                    
                    guard let code = components?.queryItems?.first(where: { $0.name == "code" })?.value else {
                        continuation.resume(throwing: SpotifyAuthError.authorizationFailed)
                        return
                    }
                    
                    continuation.resume(returning: code)
                }
                
                self.authSession?.presentationContextProvider = self
                self.authSession?.prefersEphemeralWebBrowserSession = true
                self.authSession?.start()
            }
        }
    }
    
    // MARK: - Token Exchange
    
    private func exchangeCodeForToken(_ code: String) async throws -> SpotifyTokenResponse {
        let parameters = [
            "code": code,
            "redirect_uri": SpotifyConfig.redirectURI
        ]
        
        guard let request = networkManager.buildSpotifyTokenRequest(
            grantType: "authorization_code",
            parameters: parameters
        ) else {
            throw SpotifyAuthError.invalidClientCredentials
        }
        
        do {
            let response = try await networkManager.performRequest(
                request,
                responseType: SpotifyTokenResponse.self
            )
            return response
        } catch {
            throw SpotifyAuthError.networkError(error)
        }
    }
    
    // MARK: - Token Refresh
    
    func refreshToken() async throws -> String {
        guard let refreshToken = keychainHelper.getRefreshToken() else {
            throw SpotifyAuthError.tokenRefreshFailed
        }
        
        let parameters = [
            "refresh_token": refreshToken
        ]
        
        guard let request = networkManager.buildSpotifyTokenRequest(
            grantType: "refresh_token",
            parameters: parameters
        ) else {
            throw SpotifyAuthError.invalidClientCredentials
        }
        
        do {
            let response = try await networkManager.performRequest(
                request,
                responseType: SpotifyTokenResponse.self
            )
            
            try saveTokenResponse(response, preserveRefreshToken: response.refreshToken == nil)
            
            await MainActor.run {
                isAuthenticated = true
            }
            
            return response.accessToken
        } catch {
            await MainActor.run {
                isAuthenticated = false
            }
            keychainHelper.clearSpotifyTokens()
            throw SpotifyAuthError.tokenRefreshFailed
        }
    }
    
    // MARK: - Token Management
    
    private func saveTokenResponse(_ response: SpotifyTokenResponse, preserveRefreshToken: Bool = false) throws {
        let success = keychainHelper.saveAccessToken(response.accessToken)
        
        if let refreshToken = response.refreshToken {
            let refreshSuccess = keychainHelper.saveRefreshToken(refreshToken)
            if !refreshSuccess {
                throw SpotifyAuthError.tokenRefreshFailed
            }
        } else if !preserveRefreshToken {
            throw SpotifyAuthError.tokenRefreshFailed
        }
        
        let expiration = Date().addingTimeInterval(TimeInterval(response.expiresIn))
        let expirationSuccess = keychainHelper.saveTokenExpiration(expiration)
        
        if !success || !expirationSuccess {
            throw SpotifyAuthError.tokenRefreshFailed
        }
    }
    
    func getValidAccessToken() async throws -> String {
        if keychainHelper.isAccessTokenValid() {
            if let token = keychainHelper.getAccessToken() {
                return token
            }
        }
        
        return try await refreshToken()
    }
    
    // MARK: - Logout
    
    func logout() {
        authSession?.cancel()
        authSession = nil
        
        keychainHelper.clearSpotifyTokens()
        
        DispatchQueue.main.async {
            self.isAuthenticated = false
            self.isAuthenticating = false
        }
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding

extension SpotifyAuthManager: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first,
              let window = windowScene.windows.first else {
            return ASPresentationAnchor()
        }
        return window
    }
}