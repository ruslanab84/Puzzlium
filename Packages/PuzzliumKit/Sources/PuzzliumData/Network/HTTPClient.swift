import Foundation

/// The only door to the network. Features and repositories never touch URLSession directly.
public protocol HTTPClient: Sendable {
    func send<Response: Decodable & Sendable>(_ endpoint: Endpoint<Response>) async throws -> Response
}

public struct APIConfiguration: Sendable {
    public let baseURL: URL
    public let timeout: TimeInterval

    public init(baseURL: URL, timeout: TimeInterval = 15) {
        precondition(baseURL.scheme == "https", "API must use HTTPS")
        self.baseURL = baseURL
        self.timeout = timeout
    }
}

public enum HTTPMethod: String, Sendable {
    case get = "GET"
}

public struct Endpoint<Response: Decodable & Sendable>: Sendable {
    public let path: String
    public let method: HTTPMethod
    public let queryItems: [URLQueryItem]

    public init(path: String, method: HTTPMethod = .get, queryItems: [URLQueryItem] = []) {
        self.path = path
        self.method = method
        self.queryItems = queryItems
    }
}

public enum APIError: Error, Equatable {
    case invalidURL
    case invalidResponse
    case status(Int)
    case decoding(String)
}

public struct URLSessionHTTPClient: HTTPClient {
    private let configuration: APIConfiguration
    private let session: URLSession

    public init(configuration: APIConfiguration, session: URLSession = .shared) {
        self.configuration = configuration
        self.session = session
    }

    public func send<Response: Decodable & Sendable>(_ endpoint: Endpoint<Response>) async throws -> Response {
        var components = URLComponents(
            url: configuration.baseURL.appending(path: endpoint.path),
            resolvingAgainstBaseURL: false
        )
        if !endpoint.queryItems.isEmpty {
            components?.queryItems = endpoint.queryItems
        }
        guard let url = components?.url else { throw APIError.invalidURL }

        var request = URLRequest(url: url, timeoutInterval: configuration.timeout)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(Locale.preferredLanguages.prefix(3).joined(separator: ", "), forHTTPHeaderField: "Accept-Language")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else { throw APIError.status(http.statusCode) }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw APIError.decoding(String(describing: error))
        }
    }
}
