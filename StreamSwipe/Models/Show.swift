import Foundation

struct Show: Identifiable, Codable, Hashable {
    enum ContentType: String, Codable, CaseIterable, Identifiable {
        case movie
        case series

        var id: String { rawValue }

        var title: String {
            switch self {
            case .movie:
                return "Movie"
            case .series:
                return "Series"
            }
        }
    }

    let id: UUID
    let title: String
    let synopsis: String
    let streamingService: StreamingService
    let type: ContentType
    let genres: [Genre]
    let releaseYear: Int?
    let runtimeMinutes: Int?
    let artworkURL: URL?
    let maturityRating: String?

    init(id: UUID = UUID(),
         title: String,
         synopsis: String,
         streamingService: StreamingService,
         type: ContentType,
         genres: [Genre],
         releaseYear: Int? = nil,
         runtimeMinutes: Int? = nil,
         artworkURL: URL? = nil,
         maturityRating: String? = nil) {
        self.id = id
        self.title = title
        self.synopsis = synopsis
        self.streamingService = streamingService
        self.type = type
        self.genres = genres
        self.releaseYear = releaseYear
        self.runtimeMinutes = runtimeMinutes
        self.artworkURL = artworkURL
        self.maturityRating = maturityRating
    }
}

struct Genre: Identifiable, Codable, Hashable {
    let id: String
    let name: String
}

enum StreamingService: String, Codable, CaseIterable, Identifiable {
    case netflix
    case hulu
    case primeVideo = "prime_video"
    case disneyPlus = "disney_plus"
    case max
    case appleTVPlus = "apple_tv_plus"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .netflix: return "Netflix"
        case .hulu: return "Hulu"
        case .primeVideo: return "Prime Video"
        case .disneyPlus: return "Disney+"
        case .max: return "Max"
        case .appleTVPlus: return "Apple TV+"
        }
    }
}
