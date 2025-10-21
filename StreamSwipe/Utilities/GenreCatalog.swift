import Foundation

actor GenreCatalog {
    private var genres: [Genre]?

    var cachedGenres: [Genre]? {
        get async { genres }
    }

    func store(genres: [Genre]) {
        self.genres = genres
    }

    static func memoryCache() -> GenreCatalog {
        GenreCatalog()
    }
}
