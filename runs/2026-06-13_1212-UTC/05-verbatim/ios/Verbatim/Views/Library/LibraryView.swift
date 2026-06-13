import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(ProStore.self) private var pro
    @Environment(\.modelContext) private var context
    @Query(sort: \Passage.dateAdded, order: .reverse) private var passages: [Passage]

    @State private var search = ""
    @State private var filter: PassageCategory? = nil
    @State private var showAdd = false
    @State private var showPaywall = false

    private var filtered: [Passage] {
        passages.filter { p in
            (filter == nil || p.category == filter) &&
            (search.isEmpty
             || p.title.localizedCaseInsensitiveContains(search)
             || p.source.localizedCaseInsensitiveContains(search)
             || p.fullText.localizedCaseInsensitiveContains(search))
        }
    }

    private var atCap: Bool { !pro.isPro && passages.count >= ProStore.freePassageCap }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                content
            }
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if atCap { Haptics.warning(); showPaywall = true }
                        else { Haptics.tap(); showAdd = true }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                    }
                    .accessibilityLabel("Add passage")
                }
            }
            .navigationDestination(for: Passage.self) { PassageDetailView(passage: $0) }
            .sheet(isPresented: $showAdd) { AddPassageView() }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    @ViewBuilder private var content: some View {
        if passages.isEmpty {
            EmptyStateView(icon: "books.vertical.fill",
                           title: "Your library is empty",
                           message: "Add a poem, scripture, speech, or your vows and Verbatim will help you learn it by heart.",
                           actionTitle: "Add a passage") { showAdd = true }
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    FilterRow(filter: $filter)
                    searchBar
                    if atCap { capBanner }

                    if filtered.isEmpty {
                        EmptyStateView(icon: "magnifyingglass",
                                       title: "No passages found",
                                       message: "Try a different search or clear the filter.")
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(filtered) { passage in
                                NavigationLink(value: passage) {
                                    PassageRow(passage: passage)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
        }
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass").foregroundStyle(Theme.inkSoft)
            TextField("Search title, author, text…", text: $search)
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
        .padding(.horizontal, 16)
    }

    private var capBanner: some View {
        Button { Haptics.tap(); showPaywall = true } label: {
            HStack(spacing: 12) {
                Image(systemName: "lock.fill").foregroundStyle(Theme.accent)
                Text("Free limit reached (\(ProStore.freePassageCap) passages). Unlock Pro for unlimited.")
                    .font(Theme.rounded(13, .semibold)).foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.leading)
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(Theme.inkFaint)
            }
            .padding(12)
            .background(Theme.accentSoft.opacity(0.5), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
    }
}

private struct FilterRow: View {
    @Binding var filter: PassageCategory?
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Chip(title: "All", on: filter == nil) { filter = nil }
                ForEach(PassageCategory.allCases) { c in
                    Chip(title: c.displayName, on: filter == c) {
                        filter = (filter == c) ? nil : c
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .accessibilityLabel("Filter by category")
    }
    struct Chip: View {
        let title: String; let on: Bool; let action: () -> Void
        var body: some View {
            Button { Haptics.tap(); action() } label: {
                Text(title)
                    .font(Theme.rounded(14, .semibold))
                    .foregroundStyle(on ? .white : Theme.inkSoft)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(on ? Theme.accent : Theme.surfaceAlt, in: Capsule())
            }
        }
    }
}

private struct PassageRow: View {
    let passage: Passage
    var body: some View {
        Card {
            HStack(spacing: 14) {
                MasteryRing(level: passage.masteryLevel, size: 46)
                VStack(alignment: .leading, spacing: 4) {
                    Text(passage.title)
                        .font(Theme.serif(18, .bold)).foregroundStyle(Theme.ink)
                        .lineLimit(2)
                    HStack(spacing: 6) {
                        Image(systemName: passage.category.icon)
                            .font(.system(size: 11)).foregroundStyle(Theme.accent)
                            .accessibilityHidden(true)
                        Text(passage.source.isEmpty ? passage.category.displayName : passage.source)
                            .font(Theme.rounded(13, .medium)).foregroundStyle(Theme.inkSoft)
                            .lineLimit(1)
                        Text("· \(passage.wordCount) words")
                            .font(Theme.rounded(13, .regular)).foregroundStyle(Theme.inkFaint)
                            .lineLimit(1)
                    }
                    if passage.isDue() {
                        Pill(text: "Due for review", color: Theme.accent)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(Theme.inkFaint)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(passage.title), \(passage.category.displayName), mastery \(passage.masteryLevel) of 5\(passage.isDue() ? ", due for review" : "")")
    }
}
