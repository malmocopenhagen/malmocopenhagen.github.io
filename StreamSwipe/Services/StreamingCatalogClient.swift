import Foundation

struct StreamingCatalogClient {
    var fetchShows: @Sendable (DiscoveryFilters) async throws -> [Show]
    var fetchGenres: @Sendable () async throws -> [Genre]
    var recordSave: @Sendable (Show) async throws -> Void
    var recordSkip: @Sendable (Show) async throws -> Void
}

extension StreamingCatalogClient {
    static func live(environment: StreamingCatalogEnvironment = StreamingCatalogEnvironment(),
                     session: URLSession = .shared) -> StreamingCatalogClient {
        let transport = session

        func buildRequest(path: String, queryItems: [URLQueryItem] = []) throws -> URLRequest {
            guard var components = URLComponents(url: environment.baseURL.appending(path: path), resolvingAgainstBaseURL: false) else {
                throw StreamingCatalogError.invalidURL
            }
            if !queryItems.isEmpty {
                components.queryItems = queryItems
            }
            guard let url = components.url else { throw StreamingCatalogError.invalidURL }
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.addValue("Bearer \(environment.apiKey)", forHTTPHeaderField: "Authorization")
            return request
        }

        func request<T: Decodable>(_ type: T.Type, path: String, queryItems: [URLQueryItem] = []) async throws -> T {
            let request = try buildRequest(path: path, queryItems: queryItems)
            let (data, response) = try await transport.data(for: request)
            guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
                throw StreamingCatalogError.network(statusCode: (response as? HTTPURLResponse)?.statusCode ?? -1)
            }
            return try JSONDecoder.streamSwipe.decode(T.self, from: data)
        }

        return StreamingCatalogClient(
            fetchShows: { filters in
                let payload = try await request(ShowEnvelope.self,
                                                path: "/v1/catalog",
                                                queryItems: filters.queryItems)
                return payload.results
            },
            fetchGenres: {
                let envelope = try await request(GenreEnvelope.self, path: "/v1/genres")
                return envelope.results
            },
            recordSave: { show in
                guard environment.canWrite else { return }
                var request = try buildRequest(path: "/v1/interactions")
                request.httpMethod = "POST"
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try JSONEncoder.streamSwipe.encode(InteractionPayload(action: .save, showID: show.id))
                _ = try await transport.data(for: request)
            },
            recordSkip: { show in
                guard environment.canWrite else { return }
                var request = try buildRequest(path: "/v1/interactions")
                request.httpMethod = "POST"
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try JSONEncoder.streamSwipe.encode(InteractionPayload(action: .skip, showID: show.id))
                _ = try await transport.data(for: request)
            }
        )
    }

    static var autodetected: StreamingCatalogClient {
        let environment = StreamingCatalogEnvironment()
        if environment.isConfigured {
            return .live(environment: environment)
        } else {
            return .mock()
        }
    }

    static func mock(shows: [Show] = SampleData.shows, genres: [Genre] = SampleData.genres) -> StreamingCatalogClient {
        StreamingCatalogClient(
            fetchShows: { _ in shows },
            fetchGenres: { genres },
            recordSave: { _ in },
            recordSkip: { _ in }
        )
    }
}

struct StreamingCatalogEnvironment {
    let baseURL: URL
    let apiKey: String
    let canWrite: Bool
    let isConfigured: Bool

    init() {
        var hasBaseURL = false
        var hasAPIKey = false
        if let urlString = ProcessInfo.processInfo.environment["STREAMSWIPE_BASE_URL"],
           let url = URL(string: urlString) {
            self.baseURL = url
            hasBaseURL = true
        } else {
            self.baseURL = URL(string: "https://api.example.com")!
        }

        if let key = ProcessInfo.processInfo.environment["STREAMSWIPE_API_KEY"], !key.isEmpty {
            self.apiKey = key
            hasAPIKey = true
        } else {
            self.apiKey = "demo-key"
        }

        if let canWriteString = ProcessInfo.processInfo.environment["STREAMSWIPE_ENABLE_WRITE"],
           let bool = Bool(canWriteString) {
            self.canWrite = bool
        } else {
            self.canWrite = false
        }
        self.isConfigured = hasBaseURL && hasAPIKey
    }
}

private enum StreamingCatalogError: LocalizedError {
    case invalidURL
    case network(statusCode: Int)
}

private struct ShowEnvelope: Decodable {
    let results: [Show]
}

private struct GenreEnvelope: Decodable {
    let results: [Genre]
}

private struct InteractionPayload: Encodable {
    enum Action: String, Encodable {
        case save
        case skip
    }

    let action: Action
    let showID: UUID
    let createdAt = Date()
}

extension DiscoveryFilters {
    fileprivate var queryItems: [URLQueryItem] {
        var items: [URLQueryItem] = []

        if selectedServices.count != StreamingService.allCases.count {
            let services = selectedServices.map { $0.rawValue }.sorted().joined(separator: ",")
            items.append(URLQueryItem(name: "services", value: services))
        }

        if !selectedGenres.isEmpty {
            let genres = selectedGenres.map { $0.id }.sorted().joined(separator: ",")
            items.append(URLQueryItem(name: "genres", value: genres))
        }

        if includedTypes.count != Show.ContentType.allCases.count {
            let types = includedTypes.map { $0.rawValue }.sorted().joined(separator: ",")
            items.append(URLQueryItem(name: "types", value: types))
        }

        if let minYear = minimumReleaseYear {
            items.append(URLQueryItem(name: "min_year", value: String(minYear)))
        }

        if let maxRuntime = maximumRuntimeMinutes {
            items.append(URLQueryItem(name: "max_runtime", value: String(maxRuntime)))
        }

        return items
    }
}

extension JSONDecoder {
    static let streamSwipe: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}

extension JSONEncoder {
    static let streamSwipe: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
}

enum SampleData {
    static let genres: [Genre] = [
        Genre(id: "adventure", name: "Adventure"),
        Genre(id: "drama", name: "Drama"),
        Genre(id: "comedy", name: "Comedy"),
        Genre(id: "sci-fi", name: "Sci-Fi")
    ]

    static let shows: [Show] = [
        Show(title: "The Axiom",
             synopsis: "A daring crew explores an abandoned starship hiding a conspiracy.",
             streamingService: .netflix,
             type: .series,
             genres: [SampleData.genres[1], SampleData.genres[3]],
             releaseYear: 2023,
             runtimeMinutes: 48,
             artworkURL: URL(string: "https://images.example.com/axiom.jpg"),
             maturityRating: "TV-14"),
        Show(title: "Palm Dreams",
             synopsis: "Two chefs reinvent their careers on a tropical food tour.",
             streamingService: .hulu,
             type: .series,
             genres: [SampleData.genres[1], SampleData.genres[2]],
             releaseYear: 2022,
             runtimeMinutes: 42,
             artworkURL: URL(string: "https://images.example.com/palmdreams.jpg"),
             maturityRating: "TV-PG"),
        Show(title: "Waypoint",
             synopsis: "An astronaut fights to save their family after a wormhole jump goes wrong.",
             streamingService: .primeVideo,
             type: .movie,
             genres: [SampleData.genres[0], SampleData.genres[3]],
             releaseYear: 2021,
             runtimeMinutes: 118,
             artworkURL: URL(string: "https://images.example.com/waypoint.jpg"),
             maturityRating: "PG-13")
    ]
}
