import Foundation
import SwiftUI

@MainActor
final class ShowDiscoveryViewModel: ObservableObject {
    @Published private(set) var shows: [Show] = []
    @Published private(set) var filters: DiscoveryFilters = .default
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?

    private let catalogClient: StreamingCatalogClient
    private let genreCache: GenreCatalog

    init(catalogClient: StreamingCatalogClient = .autodetected,
         genreCache: GenreCatalog = .memoryCache()) {
        self.catalogClient = catalogClient
        self.genreCache = genreCache
    }

    func reload() async {
        isLoading = true
        error = nil
        do {
            let shows = try await catalogClient.fetchShows(using: filters)
            withAnimation {
                self.shows = shows
            }
        } catch {
            self.error = error
        }
        isLoading = false
    }

    func updateFilters(_ filters: DiscoveryFilters) async {
        guard filters != self.filters else { return }
        self.filters = filters
        await reload()
    }

    func handleSwipeAction(_ action: SwipeAction, for show: Show) {
        switch action {
        case .save:
            Task {
                do {
                    try await catalogClient.recordSave(show: show)
                } catch {
                    #if DEBUG
                    print("Failed to record save: \(error)")
                    #endif
                }
            }
        case .skip:
            Task {
                do {
                    try await catalogClient.recordSkip(show: show)
                } catch {
                    #if DEBUG
                    print("Failed to record skip: \(error)")
                    #endif
                }
            }
        }

        if let index = shows.firstIndex(of: show) {
            withAnimation {
                shows.remove(at: index)
            }
        }
    }

    func fetchAvailableGenres() async throws -> [Genre] {
        if let cached = await genreCache.cachedGenres {
            return cached
        }
        let fetched = try await catalogClient.fetchGenres()
        await genreCache.store(genres: fetched)
        return fetched
    }
}

enum SwipeAction {
    case save
    case skip
}
