import SwiftUI
import SwiftData

struct ProgressionsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Progression.modifiedDate, order: .reverse) private var progressions: [Progression]
    @State private var showAdd = false
    @State private var searchText = ""
    @State private var selectedGenre: ProgressionGenre? = nil
    @AppStorage(ChordSettings.showRomanNumerals) private var showRomanNumerals = true

    private var filtered: [Progression] {
        progressions.filter { p in
            let matchesGenre = selectedGenre == nil || p.genre == selectedGenre
            let matchesSearch = searchText.isEmpty ||
                p.title.localizedCaseInsensitiveContains(searchText) ||
                p.chordSummary.localizedCaseInsensitiveContains(searchText)
            return matchesGenre && matchesSearch
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if progressions.isEmpty {
                    ContentUnavailableView {
                        Label("No Progressions Yet", systemImage: "music.note.list")
                    } description: {
                        Text("Tap + to create your first chord progression sketch.")
                    } actions: {
                        Button("New Progression") { showAdd = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        genreFilterRow

                        if filtered.isEmpty {
                            ContentUnavailableView("No Results", systemImage: "magnifyingglass")
                                .listRowBackground(Color.clear)
                        } else {
                            Section("\(filtered.count) progression\(filtered.count == 1 ? "" : "s")") {
                                ForEach(filtered) { progression in
                                    NavigationLink(destination: ProgressionDetailView(progression: progression)) {
                                        ProgressionRow(progression: progression, showRomanNumerals: showRomanNumerals)
                                    }
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            context.delete(progression)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                    .swipeActions(edge: .leading) {
                                        Button {
                                            progression.isFavorite.toggle()
                                        } label: {
                                            Label(progression.isFavorite ? "Unfavorite" : "Favorite",
                                                  systemImage: progression.isFavorite ? "star.slash" : "star.fill")
                                        }
                                        .tint(.yellow)
                                    }
                                }
                            }
                        }
                    }
                    .searchable(text: $searchText, prompt: "Search progressions")
                }
            }
            .navigationTitle("Progressions")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showAdd = true } label: {
                        Image(systemName: "plus").accessibilityLabel("New progression")
                    }
                }
            }
            .sheet(isPresented: $showAdd) {
                AddProgressionView()
            }
        }
    }

    private var genreFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(label: "All", isSelected: selectedGenre == nil) {
                    selectedGenre = nil
                }
                ForEach(ProgressionGenre.allCases, id: \.self) { genre in
                    FilterChip(label: genre.rawValue, isSelected: selectedGenre == genre) {
                        selectedGenre = selectedGenre == genre ? nil : genre
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
    }
}

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(isSelected ? ChordTheme.teal : Color(.secondarySystemGroupedBackground),
                            in: Capsule())
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct ProgressionRow: View {
    let progression: Progression
    let showRomanNumerals: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(progression.title)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                if progression.isFavorite {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                        .accessibilityHidden(true)
                }
                HStack(spacing: 4) {
                    Image(systemName: progression.genre.icon)
                        .font(.caption2)
                    Text(progression.genre.rawValue)
                        .font(.caption2)
                }
                .foregroundStyle(ChordTheme.genreColor(progression.genre))
            }

            if !progression.sortedChords.isEmpty {
                Text(progression.chordSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            HStack(spacing: 12) {
                Label("\(progression.keyName)", systemImage: "music.note")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Label("\(progression.tempo) BPM", systemImage: "metronome.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Label("\(progression.chords.count) chord\(progression.chords.count == 1 ? "" : "s")", systemImage: "squares.leading.rectangle")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(progression.title), \(progression.genre.rawValue), key of \(progression.keyName), \(progression.chords.count) chords")
    }
}
