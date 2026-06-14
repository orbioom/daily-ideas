import SwiftUI
import SwiftData

/// Browse the whole word bank: searchable, filterable, tap to push Word Detail.
struct LexiconView: View {
    @Environment(\.modelContext) private var context
    @Query private var progress: [WordProgress]
    @AppStorage("isPro") private var isPro = false
    @State private var model = LexiconViewModel()
    @State private var showPaywall = false

    private var progressByID: [String: WordProgress] {
        Dictionary(progress.map { ($0.wordID, $0) }, uniquingKeysWith: { a, _ in a })
    }

    private var results: [VocabWord] { model.results(progressByID: progressByID) }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                VStack(spacing: 0) {
                    filterBar
                    if results.isEmpty {
                        EmptyStateView(systemImage: "magnifyingglass",
                                       title: "No words found",
                                       message: model.hasActiveFilter
                                            ? "Nothing matches these filters. Try clearing them."
                                            : "Your lexicon is empty.",
                                       actionTitle: model.hasActiveFilter ? "Clear filters" : nil) {
                            model.clear()
                        }
                        .frame(maxHeight: .infinity)
                    } else {
                        list
                    }
                }
            }
            .navigationTitle("Lexicon")
            .searchable(text: $model.query, prompt: "Search words or meanings")
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private var list: some View {
        List {
            Section {
                ForEach(results) { word in
                    let locked = word.tier.requiresPro && !isPro
                    if locked {
                        Button { showPaywall = true } label: { row(word, locked: true) }
                            .buttonStyle(.plain)
                            .listRowBackground(Theme.bg)
                            .listRowSeparator(.hidden)
                    } else {
                        NavigationLink(value: word.id) { row(word, locked: false) }
                            .listRowBackground(Theme.bg)
                            .listRowSeparator(.hidden)
                    }
                }
            } header: {
                Text("\(results.count) words")
                    .font(Theme.rounded(12, .medium))
                    .foregroundStyle(Theme.inkFaint)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .navigationDestination(for: String.self) { id in
            if let word = WordBank.word(id: id) {
                WordDetailView(word: word)
            } else {
                EmptyStateView(systemImage: "exclamationmark.triangle",
                               title: "Word unavailable",
                               message: "This entry could not be loaded.")
            }
        }
    }

    private func row(_ word: VocabWord, locked: Bool) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(word.word)
                        .font(Theme.serif(19, .semibold))
                        .foregroundStyle(locked ? Theme.inkFaint : Theme.ink)
                    POSTag(pos: word.partOfSpeech)
                }
                Text(word.definition)
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
                    .lineLimit(1)
            }
            Spacer()
            if locked {
                ProLockBadge()
            } else {
                statusIcons(for: word)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Theme.hairline))
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func statusIcons(for word: VocabWord) -> some View {
        let p = progressByID[word.id]
        HStack(spacing: 6) {
            if p?.favorite == true {
                Image(systemName: "star.fill").font(.system(size: 12)).foregroundStyle(Theme.gold)
            }
            if p?.learned == true {
                Image(systemName: "checkmark.seal.fill").font(.system(size: 13)).foregroundStyle(Theme.good)
            }
            Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.inkFaint)
        }
    }

    // MARK: - Filter bar

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Menu {
                    Picker("Status", selection: $model.statusFilter) {
                        ForEach(LexiconViewModel.StatusFilter.allCases) { s in
                            Text(s.label).tag(s)
                        }
                    }
                } label: {
                    FilterPill(text: model.statusFilter == .all ? "Status" : model.statusFilter.label,
                               active: model.statusFilter != .all, icon: "line.3.horizontal.decrease")
                }

                Menu {
                    Button("All tiers") { model.tierFilter = nil }
                    ForEach(WordTier.allCases) { t in
                        Button(t.label) { model.tierFilter = t }
                    }
                } label: {
                    FilterPill(text: model.tierFilter?.label ?? "Tier",
                               active: model.tierFilter != nil, icon: "books.vertical")
                }

                Menu {
                    Button("All types") { model.posFilter = nil }
                    ForEach(PartOfSpeech.allCases) { p in
                        Button(p.label) { model.posFilter = p }
                    }
                } label: {
                    FilterPill(text: model.posFilter?.label ?? "Type",
                               active: model.posFilter != nil, icon: "textformat")
                }

                Menu {
                    Button("All tags") { model.tagFilter = nil }
                    ForEach(WordBank.allTags, id: \.self) { tag in
                        Button(tag.capitalized) { model.tagFilter = tag }
                    }
                } label: {
                    FilterPill(text: model.tagFilter?.capitalized ?? "Tag",
                               active: model.tagFilter != nil, icon: "tag")
                }

                if model.hasActiveFilter {
                    Button { Haptics.tap(); model.clear() } label: {
                        FilterPill(text: "Clear", active: true, icon: "xmark")
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }
}

struct FilterPill: View {
    let text: String
    var active: Bool = false
    var icon: String? = nil
    var body: some View {
        HStack(spacing: 5) {
            if let icon { Image(systemName: icon).font(.system(size: 11, weight: .semibold)) }
            Text(text).font(Theme.rounded(13, .medium))
        }
        .foregroundStyle(active ? .white : Theme.ink)
        .padding(.horizontal, 12).padding(.vertical, 7)
        .background(active ? Theme.accent : Theme.surface, in: Capsule())
        .overlay(Capsule().strokeBorder(active ? .clear : Theme.hairline))
    }
}
