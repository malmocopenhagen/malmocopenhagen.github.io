import SwiftUI

struct SwipeDeckView: View {
    let shows: [Show]
    let onAction: (SwipeAction, Show) -> Void

    @State private var dragState: DragState = .inactive

    private let horizontalThreshold: CGFloat = 120

    var body: some View {
        GeometryReader { proxy in
            let deck = Array(shows.enumerated().reversed())

            ZStack {
                ForEach(deck, id: \.element.id) { pair in
                    let index = pair.offset
                    let show = pair.element
                    let depth = min(index, 3)
                    let isTopCard = show.id == shows.first?.id

                    ShowCardView(show: show)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .offset(x: isTopCard ? dragState.translation.width : 0,
                                y: isTopCard ? dragState.translation.height : CGFloat(depth) * -12)
                        .rotationEffect(.degrees(isTopCard ? dragState.rotationDegrees : 0))
                        .scaleEffect(isTopCard ? 1 : max(0.8, 1 - (CGFloat(depth) * 0.04)))
                        .blur(radius: isTopCard ? 0 : CGFloat(depth) * 1.5)
                        .animation(.interactiveSpring(response: 0.4, dampingFraction: 0.75), value: shows.count)
                        .overlay(alignment: .topLeading) {
                            if isTopCard && dragState.translation.width > 0 {
                                SwipeBadge(text: "Save", color: .green)
                                    .rotationEffect(.degrees(-15))
                                    .padding(32)
                                    .opacity(Double(min(dragState.translation.width / horizontalThreshold, 1)))
                            }
                        }
                        .overlay(alignment: .topTrailing) {
                            if isTopCard && dragState.translation.width < 0 {
                                SwipeBadge(text: "Skip", color: .red)
                                    .rotationEffect(.degrees(15))
                                    .padding(32)
                                    .opacity(Double(min(abs(dragState.translation.width) / horizontalThreshold, 1)))
                            }
                        }
                        .gesture(isTopCard ? dragGesture(for: show) : nil)
                        .allowsHitTesting(isTopCard)
                        .accessibilityAddTraits(isTopCard ? [.isButton] : [])
                        .accessibilityHint(isTopCard ? "Swipe right to save, left to skip." : nil)
                        .zIndex(isTopCard ? 10 : Double(-depth))
                }
            }
        }
    }

    private func dragGesture(for show: Show) -> some Gesture {
        DragGesture()
            .onChanged { value in
                dragState = .dragging(translation: value.translation)
            }
            .onEnded { value in
                let translation = value.translation
                let velocity = value.predictedEndTranslation

                if translation.width > horizontalThreshold || velocity.width > horizontalThreshold {
                    withAnimation(.spring()) {
                        dragState = .inactive
                    }
                    onAction(.save, show)
                } else if translation.width < -horizontalThreshold || velocity.width < -horizontalThreshold {
                    withAnimation(.spring()) {
                        dragState = .inactive
                    }
                    onAction(.skip, show)
                } else {
                    withAnimation(.spring()) {
                        dragState = .inactive
                    }
                }
            }
    }
}

private struct SwipeBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text.uppercased())
            .font(.headline)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(
                Capsule()
                    .stroke(color.opacity(0.8), lineWidth: 2)
            )
            .foregroundStyle(color)
    }
}

private enum DragState {
    case inactive
    case dragging(translation: CGSize)

    var translation: CGSize {
        switch self {
        case .inactive: return .zero
        case let .dragging(translation): return translation
        }
    }

    var rotationDegrees: Double {
        Double(translation.width / 12)
    }
}
