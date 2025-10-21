import SwiftUI

struct ShowCardView: View {
    let show: Show
    @State private var isExpanded = false

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncArtworkView(url: show.artworkURL)
                .clipped()

            LinearGradient(colors: [Color.black.opacity(0.9), Color.black.opacity(0.0)],
                           startPoint: .bottom, endPoint: .top)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Label(show.streamingService.title, systemImage: "play.tv")
                        .font(.caption)
                        .padding(6)
                        .background(.ultraThinMaterial, in: Capsule())

                    Text(show.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .lineLimit(2)
                        .accessibilityAddTraits(.isHeader)

                    HStack(spacing: 8) {
                        if let year = show.releaseYear {
                            Text(String(year))
                        }
                        Text(show.type.title)
                        if let runtime = show.runtimeMinutes {
                            Text("\(runtime) min")
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(show.synopsis)
                        .lineLimit(isExpanded ? nil : 3)
                        .font(.callout)
                        .transition(.opacity)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(show.genres) { genre in
                                Text(genre.name)
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(.thinMaterial, in: Capsule())
                            }
                        }
                    }
                }

                Button {
                    withAnimation(.easeInOut) {
                        isExpanded.toggle()
                    }
                } label: {
                    Label(isExpanded ? "Show Less" : "Show More", systemImage: "chevron.\(isExpanded ? "up" : "down")")
                        .font(.subheadline)
                }
                .buttonStyle(.borderedProminent)
                .tint(.accentColor)
                .padding(.top, 8)
            }
            .padding(24)
            .foregroundColor(.white)
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(radius: 8, x: 0, y: 8)
    }
}

private struct AsyncArtworkView: View {
    let url: URL?
    @StateObject private var loader = ImageLoader()

    var body: some View {
        ZStack {
            switch loader.state {
            case .idle:
                Color(.secondarySystemBackground)
            case .loading:
                ZStack {
                    Color(.secondarySystemBackground)
                    ProgressView()
                }
            case let .loaded(image):
                GeometryReader { proxy in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                }
            case .failed:
                ZStack {
                    Color(.tertiarySystemBackground)
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .onAppear { loader.load(from: url) }
        .onChange(of: url) { newValue in
            loader.load(from: newValue)
        }
    }
}
