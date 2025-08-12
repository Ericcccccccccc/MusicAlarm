import Foundation

class NetworkManager {
    
    static let shared = NetworkManager()
    
    private let session: URLSession
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Generic Request Method
    
    func performRequest<T: Codable>(
        _ request: URLRequest,
        responseType: T.Type
    ) async throws -> T {
        let (data, response) = try await session.data(for: request)
        
        try validateResponse(response)
        
        do {
            let decodedResponse = try JSONDecoder().decode(responseType, from: data)
            return decodedResponse
        } catch {
            print("JSON Decoding Error: \(error)")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw JSON: \(jsonString)")
            }
            throw SpotifyAPIError.invalidResponse
        }
    }
    
    // MARK: - Data Request Method
    
    func performDataRequest(_ request: URLRequest) async throws -> Data {
        let (data, response) = try await session.data(for: request)
        
        try validateResponse(response)
        
        return data
    }
    
    // MARK: - Response Validation
    
    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SpotifyAPIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401:
            throw SpotifyAPIError.unauthorized
        case 400:
            throw SpotifyAPIError.badRequest
        case 404:
            throw SpotifyAPIError.notFound
        case 429:
            throw SpotifyAPIError.rateLimited
        case 500...599:
            throw SpotifyAPIError.serverError
        default:
            throw SpotifyAPIError.invalidResponse
        }
    }
    
    // MARK: - Request Builder Methods
    
    func buildGETRequest(
        url: URL,
        headers: [String: String]? = nil
    ) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let headers = headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        return request
    }
    
    func buildPOSTRequest(
        url: URL,
        body: Data? = nil,
        headers: [String: String]? = nil
    ) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        
        if let headers = headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        return request
    }
    
    func buildFormDataRequest(
        url: URL,
        parameters: [String: String],
        headers: [String: String]? = nil
    ) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        var components = URLComponents()
        components.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        request.httpBody = components.percentEncodedQuery?.data(using: .utf8)
        
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        if let headers = headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        return request
    }
    
    // MARK: - Spotify Specific Request Methods
    
    func buildSpotifyAPIRequest(
        endpoint: SpotifyConfig.APIEndpoint,
        accessToken: String
    ) -> URLRequest? {
        guard let url = endpoint.url else { return nil }
        
        let headers = [
            "Authorization": "Bearer \(accessToken)",
            "Content-Type": "application/json"
        ]
        
        return buildGETRequest(url: url, headers: headers)
    }
    
    func buildSpotifyTokenRequest(
        grantType: String,
        parameters: [String: String]
    ) -> URLRequest? {
        guard let url = URL(string: SpotifyConfig.tokenURL) else { return nil }
        
        var allParameters = parameters
        allParameters["grant_type"] = grantType
        allParameters["client_id"] = SpotifyConfig.clientID
        
        let headers = [
            "Content-Type": "application/x-www-form-urlencoded"
        ]
        
        return buildFormDataRequest(url: url, parameters: allParameters, headers: headers)
    }
    
    // MARK: - Error Handling Helpers
    
    func handleNetworkError(_ error: Error) -> SpotifyAPIError {
        if error is DecodingError {
            return .invalidResponse
        }
        
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return .networkError(urlError)
            case .timedOut:
                return .networkError(urlError)
            default:
                return .networkError(urlError)
            }
        }
        
        return .networkError(error)
    }
}