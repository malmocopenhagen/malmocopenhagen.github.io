import Foundation

struct DiscoveryFilters: Equatable {
    var selectedServices: Set<StreamingService>
    var selectedGenres: Set<Genre>
    var includedTypes: Set<Show.ContentType>
    var minimumReleaseYear: Int?
    var maximumRuntimeMinutes: Int?

    static var `default`: DiscoveryFilters {
        DiscoveryFilters(selectedServices: Set(StreamingService.allCases),
                         selectedGenres: [],
                         includedTypes: Set(Show.ContentType.allCases),
                         minimumReleaseYear: nil,
                         maximumRuntimeMinutes: nil)
    }
}
