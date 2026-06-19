import SwiftUI
import SwiftData

struct SearchView: View {
    @Environment(\.modelContext) private var ctx
    @Query private var favorites: [FavoriteWord]
    @State private var engine = RhymeEngine()
    @State private var query = ""
    @State private var copiedWord: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                if query.isEmpty {
                    emptyPrompt
                } else if engine.isSearching {
                    ProgressView("Searching…").padding()
                } else {
                    resultsList
                }
            }
            .navigationTitle("Rhyme Finder")
            .onChange(of: query) { _, new in engine.search(word: new) }
        }
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField("Enter a word…", text: $query)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
            if !query.isEmpty {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray5), in: RoundedRectangle(cornerRadius: 12))
        .padding()
    }

    private var emptyPrompt: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "music.note").font(.system(size: 60)).foregroundStyle(.pink.opacity(0.5))
            Text("Find rhymes for any word").font(.title2.weight(.semibold))
            Text("Type a word above to see perfect\nand near rhymes instantly.")
                .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
            Spacer()
        }
    }

    private var resultsList: some View {
        List {
            // Stats header
            Section {
                HStack(spacing: 16) {
                    statChip(value: "\(engine.syllableCount)", label: "syllables")
                    statChip(value: "\(engine.perfectRhymes.count)", label: "perfect")
                    statChip(value: "\(engine.nearRhymes.count)", label: "near")
                }
                .listRowInsets(.init(top: 8, leading: 8, bottom: 8, trailing: 8))
                .listRowBackground(Color.clear)
            }

            // Perfect rhymes
            if !engine.perfectRhymes.isEmpty {
                Section("Perfect Rhymes") {
                    ForEach(engine.perfectRhymes) { result in
                        wordRow(result)
                    }
                }
            }

            // Near rhymes
            if !engine.nearRhymes.isEmpty {
                Section("Near Rhymes") {
                    ForEach(engine.nearRhymes.prefix(30), id: \.id) { result in
                        wordRow(result)
                    }
                }
            }

            if engine.perfectRhymes.isEmpty && engine.nearRhymes.isEmpty {
                Section {
                    ContentUnavailableView(
                        "No Rhymes Found",
                        systemImage: "music.note.list",
                        description: Text("Try a different word or check spelling.")
                    )
                    .listRowBackground(Color.clear)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func wordRow(_ result: RhymeResult) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(result.word).fontWeight(.medium)
                Text("\(result.syllables) syl.").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 12) {
                if copiedWord == result.word {
                    Image(systemName: "checkmark").foregroundStyle(.green)
                } else {
                    Button {
                        UIPasteboard.general.string = result.word
                        copiedWord = result.word
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copiedWord = nil }
                    } label: {
                        Image(systemName: "doc.on.doc").foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                let isFav = favorites.contains { $0.word == result.word }
                Button {
                    toggleFavorite(word: result.word, isFav: isFav)
                } label: {
                    Image(systemName: isFav ? "heart.fill" : "heart")
                        .foregroundStyle(isFav ? .pink : .secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .contentShape(Rectangle())
    }

    private func statChip(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.headline.weight(.bold)).foregroundStyle(.pink)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
    }

    private func toggleFavorite(word: String, isFav: Bool) {
        if isFav {
            if let f = favorites.first(where: { $0.word == word }) { ctx.delete(f) }
        } else {
            ctx.insert(FavoriteWord(word: word))
        }
    }
}
