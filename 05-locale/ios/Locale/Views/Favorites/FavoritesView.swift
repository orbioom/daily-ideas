import SwiftUI
import SwiftData

struct FavoritesView: View {
    @Query private var favorites: [FavoritePhrase]
    @Query private var allPrefs: [LocalePrefs]
    @Environment(\.modelContext) private var context

    private var prefs: LocalePrefs {
        if let p = allPrefs.first { return p }
        let p = LocalePrefs(); context.insert(p); return p
    }

    private var currentLanguage: Language {
        LanguageRegistry.all.first { $0.id == prefs.selectedLanguageId } ?? LanguageRegistry.all[0]
    }

    private var favoritePhrases: [Phrase] {
        let langId = prefs.selectedLanguageId
        let ids = favorites.filter { $0.languageId == langId }.map { $0.phraseId }
        return PhraseDatabase.shared.phrases(for: langId, categoryId: nil).filter { ids.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if favoritePhrases.isEmpty {
                    ContentUnavailableView(
                        "No Favorites Yet",
                        systemImage: "heart",
                        description: Text("Tap the heart on any phrase to save it here.")
                    )
                } else {
                    List {
                        ForEach(favoritePhrases) { phrase in
                            NavigationLink {
                                PhraseDetailView(phrase: phrase, language: currentLanguage)
                            } label: {
                                PhraseRow(phrase: phrase, isFavorite: true)
                            }
                        }
                        .onDelete(perform: deleteFavorites)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Favorites")
            .toolbar {
                if !favoritePhrases.isEmpty {
                    EditButton()
                }
            }
        }
    }

    private func deleteFavorites(at offsets: IndexSet) {
        let toDelete = offsets.map { favoritePhrases[$0] }
        for phrase in toDelete {
            if let fav = favorites.first(where: { $0.phraseId == phrase.id && $0.languageId == phrase.languageId }) {
                context.delete(fav)
            }
        }
        if prefs.hapticsEnabled {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}
