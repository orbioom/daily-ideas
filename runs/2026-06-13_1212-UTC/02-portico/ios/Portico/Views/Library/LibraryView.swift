import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(ProStore.self) private var pro
    @Environment(\.modelContext) private var context
    @Query private var saved: [SavedQuote]

    @State private var section: Section = .browse
    @State private var search = ""
    @State private var theme: QuoteTheme?
    @State private var author: QuoteAuthor = .all
    @State private var showPaywall = false

    enum Section: String, CaseIterable, Identifiable {
        case browse = "Browse", favorites = "Favorites", virtues = "Virtues"
        var id: String { rawValue }
    }

    private let today = Date()

    /// The set a free user may read: full library for Pro, free daily set otherwise.
    private var accessible: [StoicQuote] {
        pro.isPro ? QuoteLibrary.all : StoicEngine.freeDailySet(for: today, count: 6)
    }

    private var filtered: [StoicQuote] {
        accessible.filter { q in
            (theme == nil || q.theme == theme) &&
            (author == .all || q.author == author.rawValue) &&
            (search.isEmpty
             || q.text.localizedCaseInsensitiveContains(search)
             || q.author.localizedCaseInsensitiveContains(search)
             || q.source.localizedCaseInsensitiveContains(search))
        }
    }

    private var savedQuotes: [StoicQuote] {
        saved.sorted { $0.savedAt > $1.savedAt }
            .compactMap { QuoteLibrary.quote(id: $0.quoteID) }
    }

    private func isSaved(_ q: StoicQuote) -> Bool { saved.contains { $0.quoteID == q.id } }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    Picker("Section", selection: $section) {
                        ForEach(Section.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    switch section {
                    case .browse:    browseSection
                    case .favorites: favoritesSection
                    case .virtues:   virtuesSection
                    }
                }
            }
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: StoicQuote.self) { q in
                QuoteDetailView(quote: q)
            }
            .navigationDestination(for: Virtue.self) { v in
                VirtueDetailView(virtue: v)
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    // MARK: Browse

    @ViewBuilder private var browseSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            searchField
            themeChips
            authorMenu

            if !pro.isPro {
                lockedBanner
            }

            if filtered.isEmpty {
                EmptyStateView(icon: "magnifyingglass",
                               title: "Nothing here",
                               message: "Try a different theme, author, or search term.")
            } else {
                ForEach(filtered) { q in
                    NavigationLink(value: q) {
                        QuoteCard(quote: q, isSaved: isSaved(q)) { toggleSave(q) }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 28)
    }

    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass").foregroundStyle(Theme.inkSoft)
            TextField("Search by word, author, or work…", text: $search)
                .font(Theme.rounded(16, .regular))
                .autocorrectionDisabled()
            if !search.isEmpty {
                Button { search = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(Theme.inkFaint)
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(12)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.hairline, lineWidth: 1))
    }

    private var themeChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Chip(title: "All themes", on: theme == nil) { theme = nil }
                ForEach(QuoteTheme.allCases) { t in
                    Chip(title: t.rawValue, on: theme == t) {
                        theme = (theme == t) ? nil : t
                    }
                }
            }
        }
    }

    private var authorMenu: some View {
        Menu {
            ForEach(QuoteAuthor.allCases) { a in
                Button {
                    Haptics.tap(); author = a
                } label: {
                    if author == a { Label(a.rawValue, systemImage: "checkmark") }
                    else { Text(a.rawValue) }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "person.fill")
                Text(author.rawValue)
                Image(systemName: "chevron.down").font(.system(size: 11))
            }
            .font(Theme.rounded(14, .semibold))
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(Theme.surfaceAlt, in: Capsule())
        }
        .accessibilityLabel("Filter by author, currently \(author.rawValue)")
    }

    private var lockedBanner: some View {
        Button { Haptics.tap(); showPaywall = true } label: {
            HStack(spacing: 12) {
                Image(systemName: "lock.open.fill").foregroundStyle(.white)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Unlock the full library")
                        .font(Theme.rounded(15, .bold)).foregroundStyle(.white)
                    Text("\(QuoteLibrary.all.count) quotes with Portico Pro")
                        .font(Theme.rounded(12, .regular)).foregroundStyle(.white.opacity(0.9))
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.white.opacity(0.9))
            }
            .padding(14)
            .background(LinearGradient(colors: [Theme.accent, Theme.accent.opacity(0.78)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: Favorites

    @ViewBuilder private var favoritesSection: some View {
        VStack(spacing: 14) {
            if savedQuotes.isEmpty {
                EmptyStateView(icon: "bookmark",
                               title: "No favourites yet",
                               message: "Tap the bookmark on any quote to keep it here.")
            } else {
                ForEach(savedQuotes) { q in
                    NavigationLink(value: q) {
                        QuoteCard(quote: q, isSaved: true) { toggleSave(q) }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 28)
    }

    // MARK: Virtues

    private var virtuesSection: some View {
        VStack(spacing: 14) {
            Text("The four cardinal virtues are the whole of Stoic ethics: to live well is to live in accordance with them.")
                .font(Theme.rounded(14, .regular))
                .foregroundStyle(Theme.inkSoft)
                .frame(maxWidth: .infinity, alignment: .leading)
            ForEach(Virtue.allCases) { v in
                NavigationLink(value: v) {
                    Card {
                        HStack(spacing: 14) {
                            Image(systemName: v.icon)
                                .font(.system(size: 26))
                                .foregroundStyle(v.tint)
                                .frame(width: 38)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(v.rawValue)
                                    .font(Theme.serif(19, .bold))
                                    .foregroundStyle(Theme.ink)
                                Text(v.definition)
                                    .font(Theme.rounded(13, .regular))
                                    .foregroundStyle(Theme.inkSoft)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right").foregroundStyle(Theme.inkFaint)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 28)
    }

    // MARK: Actions

    private func toggleSave(_ q: StoicQuote) {
        if let existing = saved.first(where: { $0.quoteID == q.id }) {
            context.delete(existing)
        } else {
            context.insert(SavedQuote(quoteID: q.id))
        }
        try? context.save()
    }
}

/// A small filter chip used in the Library.
struct Chip: View {
    let title: String
    let on: Bool
    let action: () -> Void
    var body: some View {
        Button { Haptics.tap(); action() } label: {
            Text(title)
                .font(Theme.rounded(14, .semibold))
                .foregroundStyle(on ? .white : Theme.inkSoft)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(on ? Theme.accent : Theme.surfaceAlt, in: Capsule())
        }
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}
