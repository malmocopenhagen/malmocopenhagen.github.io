import SwiftUI
import Combine
import UIKit

@MainActor
final class ImageLoader: ObservableObject {
    enum State {
        case idle
        case loading
        case loaded(Image)
        case failed(Error)
    }

    @Published private(set) var state: State = .idle
    private var task: Task<Void, Never>?
    private var currentURL: URL?

    func load(from url: URL?) {
        if currentURL == url {
            switch state {
            case .idle, .failed:
                break
            case .loading, .loaded:
                return
            }
        }

        currentURL = url
        guard let url else {
            withAnimation { state = .failed(ImageLoaderError.missingURL) }
            return
        }

        withAnimation { state = .loading }
        task?.cancel()
        task = Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard let uiImage = UIImage(data: data) else {
                    throw ImageLoaderError.invalidImage
                }
                let image = Image(uiImage: uiImage)
                withAnimation { state = .loaded(image) }
            } catch {
                withAnimation { state = .failed(error) }
            }
        }
    }

    deinit {
        task?.cancel()
    }
}

enum ImageLoaderError: Error {
    case missingURL
    case invalidImage
}
