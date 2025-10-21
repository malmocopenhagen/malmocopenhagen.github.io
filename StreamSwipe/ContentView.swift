import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var viewModel: ShowDiscoveryViewModel
    @State private var presentingFilters = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color(.systemBackground), Color(.secondarySystemBackground)]),
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                if viewModel.isLoading && viewModel.shows.isEmpty {
                    ProgressView("Loading shows…")
                        .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
                } else if viewModel.shows.isEmpty {
                    EmptyStateView(presentingFilters: $presentingFilters)
                } else {
                    SwipeDeckView(shows: viewModel.shows,
                                  onAction: viewModel.handleSwipeAction)
                        .padding(.horizontal, 24)
                        .animation(.spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0.2), value: viewModel.shows)
                }
            }
            .navigationTitle("StreamSwipe")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        Task {
                            await viewModel.reload()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading)

                    Button {
                        presentingFilters = true
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .task {
                await viewModel.reload()
            }
            .sheet(isPresented: $presentingFilters) {
                NavigationStack {
                    FilterView(initialFilters: viewModel.filters) { newFilters in
                        Task {
                            await viewModel.updateFilters(newFilters)
                        }
                    }
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
    }
}

private struct EmptyStateView: View {
    @Binding var presentingFilters: Bool

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles.tv")
                .font(.system(size: 52))
                .foregroundStyle(.secondary)

            Text("No matches yet")
                .font(.title2).bold()

            Text("Try adjusting your filters or refreshing the catalog.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button(action: { presentingFilters = true }) {
                Label("Open Filters", systemImage: "line.3.horizontal.decrease.circle")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
