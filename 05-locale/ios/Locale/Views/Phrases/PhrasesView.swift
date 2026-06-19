import SwiftUI
import SwiftData

struct PhrasesView: View {
    @Query private var allPrefs: [LocalePrefs]
    @Query private var favorites: [FavoritePhrase]
    @Environment(\.modelContext) private var context

    private var prefs: LocalePrefs {
        if let p = allPrefs.first { return p }
        let p = LocalePrefs(); context.insert(p); return p
    }

    private var currentLanguage: Language {
        LanguageRegistry.all.first { $0.id == prefs.selectedLanguageId } ?? LanguageRegistry.all[0]
    }

    @State private var selectedCategory: PhraseCategory? = nil
    @State private var searchText = ""

    private var phrases: [Phrase] {
        let catId = selectedCategory?.id
        var list = PhraseDatabase.shared.phrases(for: prefs.selectedLanguageId, categoryId: catId)
        if !searchText.isEmpty {
            let q = searchText.lowercased()
            list = list.filter {
                $0.english.lowercased().contains(q) ||
                $0.translation.lowercased().contains(q) ||
                ($0.phonetic?.lowercased().contains(q) ?? false)
            }
        }
        return list
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                categoryScroll
                phraseList
            }
            .navigationTitle("\(currentLanguage.flag) \(currentLanguage.name)")
            .searchable(text: $searchText, prompt: "Search phrases…")
        }
    }

    private var categoryScroll: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                CategoryChip(category: nil, isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }
                ForEach(CategoryRegistry.all) { cat in
                    CategoryChip(category: cat, isSelected: selectedCategory?.id == cat.id) {
                        selectedCategory = (selectedCategory?.id == cat.id) ? nil : cat
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(.bar)
    }

    private var phraseList: some View {
        Group {
            if phrases.isEmpty {
                ContentUnavailableView(
                    searchText.isEmpty ? "No Phrases" : "No Results",
                    systemImage: searchText.isEmpty ? "text.bubble" : "magnifyingglass",
                    description: Text(searchText.isEmpty ? "Select a language to get started." : "Try a different search term.")
                )
            } else {
                List {
                    ForEach(phrases) { phrase in
                        NavigationLink {
                            PhraseDetailView(phrase: phrase, language: currentLanguage)
                        } label: {
                            PhraseRow(
                                phrase: phrase,
                                isFavorite: favorites.contains { $0.phraseId == phrase.id && $0.languageId == phrase.languageId }
                            )
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }
}

private struct CategoryChip: View {
    let category: PhraseCategory?
    let isSelected: Bool
    let onTap: () -> Void

    var label: String {
        if let c = category { return "\(c.emoji) \(c.name)" }
        return "All"
    }

    var body: some View {
        Button(action: onTap) {
            Text(label)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? Color.blue : Color(.secondarySystemBackground))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .accessibilityLabel(label + (isSelected ? ", selected" : ""))
    }
}

struct PhraseRow: View {
    let phrase: Phrase
    let isFavorite: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(phrase.translation)
                .font(.headline)
            Text(phrase.english)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if let ph = phrase.phonetic {
                Text(ph)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .italic()
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(phrase.translation). \(phrase.english).\(phrase.phonetic.map { " Pronunciation: \($0)" } ?? "")")
    }
}
