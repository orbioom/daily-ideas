import SwiftUI
import SwiftData

struct FavoritesView: View {
    @Environment(\.modelContext) private var ctx
    @Query(sort: \FavoriteWord.dateAdded, order: .reverse) private var favorites: [FavoriteWord]
    @State private var searchText = ""
    @State private var selectedWord: String?
    @State private var engine = RhymeEngine()

    var filtered: [FavoriteWord] {
        guard !searchText.isEmpty else { return favorites }
        return favorites.filter { $0.word.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if favorites.isEmpty {
                    emptyState
                } else {
                    favList
                }
            }
            .navigationTitle("Favorites")
            .searchable(text: $searchText, prompt: "Search favorites")
            .sheet(item: $selectedWord) { word in
                FavoriteDetailSheet(word: word)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart").font(.system(size: 60)).foregroundStyle(.pink.opacity(0.5))
            Text("No Favorites Yet").font(.title2.weight(.semibold))
            Text("Tap the heart icon on any rhyme to save it here.")
                .foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.horizontal)
        }
    }

    private var favList: some View {
        List {
            ForEach(filtered) { fav in
                Button { selectedWord = fav.word } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(fav.word).fontWeight(.medium).foregroundStyle(.primary)
                            Text("\(RhymeDatabase.syllableCount(for: fav.word)) syllables · \(RhymeDatabase.perfectRhymes(for: fav.word).count) rhymes")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundStyle(.secondary).font(.caption)
                    }
                }
            }
            .onDelete(perform: deleteFavorites)
        }
        .listStyle(.insetGrouped)
    }

    private func deleteFavorites(at offsets: IndexSet) {
        for i in offsets { ctx.delete(filtered[i]) }
    }
}

extension String: @retroactive Identifiable {
    public var id: String { self }
}

struct FavoriteDetailSheet: View {
    let word: String
    @State private var engine = RhymeEngine()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Word Info") {
                    LabeledContent("Syllables", value: "\(RhymeDatabase.syllableCount(for: word))")
                    LabeledContent("Perfect Rhymes", value: "\(RhymeDatabase.perfectRhymes(for: word).count)")
                }
                let rhymes = RhymeDatabase.perfectRhymes(for: word)
                if !rhymes.isEmpty {
                    Section("Perfect Rhymes") {
                        ForEach(rhymes, id: \.self) { r in
                            Text(r)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(word)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
