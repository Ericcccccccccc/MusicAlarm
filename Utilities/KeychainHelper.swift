import Foundation
import Security

class KeychainHelper {
    
    static let shared = KeychainHelper()
    
    private init() {}
    
    // MARK: - Save Methods
    
    func save(data: Data, forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    func save(string: String, forKey key: String) -> Bool {
        guard let data = string.data(using: .utf8) else { return false }
        return save(data: data, forKey: key)
    }
    
    // MARK: - Retrieve Methods
    
    func retrieveData(forKey key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }
    
    func retrieveString(forKey key: String) -> String? {
        guard let data = retrieveData(forKey: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    // MARK: - Update Methods
    
    func update(data: Data, forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        let updateData: [String: Any] = [
            kSecValueData as String: data
        ]
        
        let status = SecItemUpdate(query as CFDictionary, updateData as CFDictionary)
        
        if status == errSecItemNotFound {
            return save(data: data, forKey: key)
        }
        
        return status == errSecSuccess
    }
    
    func update(string: String, forKey key: String) -> Bool {
        guard let data = string.data(using: .utf8) else { return false }
        return update(data: data, forKey: key)
    }
    
    // MARK: - Delete Methods
    
    func delete(forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    func deleteAll() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    // MARK: - Exists Methods
    
    func exists(forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: false,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    // MARK: - Spotify Specific Methods
    
    func saveAccessToken(_ token: String) -> Bool {
        return save(string: token, forKey: SpotifyConfig.accessTokenKey)
    }
    
    func getAccessToken() -> String? {
        return retrieveString(forKey: SpotifyConfig.accessTokenKey)
    }
    
    func saveRefreshToken(_ token: String) -> Bool {
        return save(string: token, forKey: SpotifyConfig.refreshTokenKey)
    }
    
    func getRefreshToken() -> String? {
        return retrieveString(forKey: SpotifyConfig.refreshTokenKey)
    }
    
    func saveTokenExpiration(_ expiration: Date) -> Bool {
        let timestamp = expiration.timeIntervalSince1970
        return save(string: "\(timestamp)", forKey: SpotifyConfig.tokenExpirationKey)
    }
    
    func getTokenExpiration() -> Date? {
        guard let timestampString = retrieveString(forKey: SpotifyConfig.tokenExpirationKey),
              let timestamp = TimeInterval(timestampString) else {
            return nil
        }
        return Date(timeIntervalSince1970: timestamp)
    }
    
    func clearSpotifyTokens() -> Bool {
        let accessTokenDeleted = delete(forKey: SpotifyConfig.accessTokenKey)
        let refreshTokenDeleted = delete(forKey: SpotifyConfig.refreshTokenKey)
        let expirationDeleted = delete(forKey: SpotifyConfig.tokenExpirationKey)
        
        return accessTokenDeleted && refreshTokenDeleted && expirationDeleted
    }
    
    func isAccessTokenValid() -> Bool {
        guard let accessToken = getAccessToken(),
              !accessToken.isEmpty,
              let expiration = getTokenExpiration() else {
            return false
        }
        
        let now = Date()
        let refreshThreshold = SpotifyConfig.tokenRefreshThreshold
        
        return now.addingTimeInterval(refreshThreshold) < expiration
    }
    
    func hasValidRefreshToken() -> Bool {
        guard let refreshToken = getRefreshToken() else { return false }
        return !refreshToken.isEmpty
    }
}