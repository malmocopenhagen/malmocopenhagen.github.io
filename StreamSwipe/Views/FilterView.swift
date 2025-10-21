import SwiftUI

struct FilterView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: ShowDiscoveryViewModel

    @State private var filters: DiscoveryFilters
    @State private var availableGenres: [Genre] = []
    @State private var isLoadingGenres = false
    @State private var genreError: String?

    let onSave: (DiscoveryFilters) -> Void

    init(initialFilters: DiscoveryFilters, onSave: @escaping (DiscoveryFilters) -> Void) {
        self._filters = State(initialValue: initialFilters)
        self.onSave = onSave
    }

    var body: some View {
        Form {
            Section("Streaming Services") {
                ForEach(StreamingService.allCases) { service in
                    Toggle(isOn: Binding(get: {
                        filters.selectedServices.contains(service)
                    }, set: { isOn in
                        if isOn {
                            filters.selectedServices.insert(service)
                        } else {
                            filters.selectedServices.remove(service)
                        }
                    })) {
                        Text(service.title)
                    }
                }
                Button("Select All") {
                    filters.selectedServices = Set(StreamingService.allCases)
                }
                .buttonStyle(.borderless)
            }

            Section("Content Type") {
                ForEach(Show.ContentType.allCases) { type in
                    Toggle(type.title, isOn: Binding(get: {
                        filters.includedTypes.contains(type)
                    }, set: { isOn in
                        if isOn {
                            filters.includedTypes.insert(type)
                        } else {
                            filters.includedTypes.remove(type)
                        }
                    }))
                }
            }

            Section("Genres") {
                if isLoadingGenres {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else if let genreError {
                    Text(genreError)
                        .foregroundStyle(.red)
                } else if availableGenres.isEmpty {
                    Text("No genres available")
                        .foregroundStyle(.secondary)
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 8)], spacing: 8) {
                        ForEach(availableGenres) { genre in
                            SelectableChip(label: genre.name, isSelected: filters.selectedGenres.contains(genre)) {
                                if filters.selectedGenres.contains(genre) {
                                    filters.selectedGenres.remove(genre)
                                } else {
                                    filters.selectedGenres.insert(genre)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Section("Release Year") {
                Stepper(value: Binding(get: {
                    filters.minimumReleaseYear ?? Calendar.current.component(.year, from: Date())
                }, set: { newValue in
                    filters.minimumReleaseYear = newValue
                }), in: 1960...Calendar.current.component(.year, from: Date())) {
                    if let minYear = filters.minimumReleaseYear {
                        Text("From \(minYear)")
                    } else {
                        Text("Any year")
                    }
                }

                Button(filters.minimumReleaseYear == nil ? "Set from 2015" : "Clear") {
                    if filters.minimumReleaseYear == nil {
                        filters.minimumReleaseYear = 2015
                    } else {
                        filters.minimumReleaseYear = nil
                    }
                }
            }

            Section("Runtime") {
                Stepper(value: Binding(get: {
                    filters.maximumRuntimeMinutes ?? 120
                }, set: { newValue in
                    filters.maximumRuntimeMinutes = newValue
                }), in: 30...240, step: 10) {
                    if let runtime = filters.maximumRuntimeMinutes {
                        Text("Up to \(runtime) minutes")
                    } else {
                        Text("Any length")
                    }
                }

                Button(filters.maximumRuntimeMinutes == nil ? "Cap at 120 min" : "Clear") {
                    if filters.maximumRuntimeMinutes == nil {
                        filters.maximumRuntimeMinutes = 120
                    } else {
                        filters.maximumRuntimeMinutes = nil
                    }
                }
            }
        }
        .navigationTitle("Filters")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close", role: .cancel) { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Apply") {
                    onSave(filters)
                    dismiss()
                }
                .disabled(!isValid)
            }
        }
        .task(loadGenres)
    }

    private var isValid: Bool {
        !filters.selectedServices.isEmpty && !filters.includedTypes.isEmpty
    }

    private func loadGenres() async {
        guard availableGenres.isEmpty else { return }
        isLoadingGenres = true
        do {
            let fetched = try await viewModel.fetchAvailableGenres()
            availableGenres = fetched.sorted { $0.name < $1.name }
            genreError = nil
        } catch {
            genreError = "Unable to load genres. Try again later."
        }
        isLoadingGenres = false
    }
}

private struct SelectableChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor.opacity(0.2) : Color(.systemBackground), in: Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.accentColor : Color(.systemGray4), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

