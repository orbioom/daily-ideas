import SwiftUI
import SwiftData

/// Browse — the curated offline catalog grouped by kind & season for quick-add.
struct BrowseScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Query private var allTitles: [Title]

    @State private var kindFilter: KindFilter = .all
    @State private var selection: CatalogEntry?
    @State private var paywallReason: PaywallReason?

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 14)]

    /// Names already in the library, lowercased, keyed by kind.
    private var addedKeys: Set<String> {
        Set(allTitles.map { "\($0.name.lowercased())|\($0.kind.rawValue)" })
    }

    private func isAdded(_ entry: CatalogEntry) -> Bool {
        addedKeys.contains("\(entry.name.lowercased())|\(entry.kind.rawValue)")
    }

    private var groups: [(title: String, entries: [CatalogEntry])] {
        let entries: [CatalogEntry]
        switch kindFilter.kind {
        case .anime: entries = CatalogData.anime
        case .manga: entries = CatalogData.manga
        case nil: entries = CatalogData.all
        }
        // Group anime by "Season Year", manga by author decade label.
        var buckets: [String: [CatalogEntry]] = [:]
        for e in entries {
            let key = groupKey(for: e)
            buckets[key, default: []].append(e)
        }
        return buckets
            .map { (title: $0.key, entries: $0.value.sorted { $0.name < $1.name }) }
            .sorted { sortKey($0.entries.first) > sortKey($1.entries.first) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        Picker("Kind", selection: $kindFilter) {
                            ForEach(KindFilter.allCases) { f in Text(f.rawValue).tag(f) }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                        ForEach(groups, id: \.title) { group in
                            VStack(alignment: .leading, spacing: 10) {
                                Text(group.title)
                                    .font(Theme.display(18, .bold))
                                    .foregroundStyle(Theme.ink)
                                    .padding(.horizontal, 16)
                                LazyVGrid(columns: columns, spacing: 14) {
                                    ForEach(group.entries) { entry in
                                        Button {
                                            Haptics.tap(settings.hapticsEnabled)
                                            selection = entry
                                        } label: {
                                            CatalogCard(entry: entry, added: isAdded(entry),
                                                        intensity: settings.accentIntensity)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Browse")
            .sheet(item: $selection) { entry in
                CatalogAddView(entry: entry, alreadyAdded: isAdded(entry)) {
                    attemptAdd(entry, status: $0)
                }
            }
            .sheet(item: $paywallReason) { reason in
                PaywallView(reason: reason)
            }
        }
    }

    private func groupKey(for e: CatalogEntry) -> String {
        if let label = e.seasonLabel { return label }
        return "by \(e.studioOrAuthor)"
    }

    private func sortKey(_ e: CatalogEntry?) -> Int { e?.year ?? 0 }

    private func attemptAdd(_ entry: CatalogEntry, status: WatchStatus) {
        guard !isAdded(entry) else { return }
        guard Pro.canAddTitle(currentCount: allTitles.count, isPro: isPro) else {
            Haptics.warning(settings.hapticsEnabled)
            paywallReason = .titleLimit
            return
        }
        let title = Title(name: entry.name,
                          kind: entry.kind,
                          status: status,
                          totalUnits: entry.defaultUnits,
                          season: entry.season,
                          seasonYear: entry.year,
                          studioOrAuthor: entry.studioOrAuthor)
        context.insert(title)
        for name in entry.genres {
            title.genres.append(Genre.findOrCreate(name, in: context))
        }
        if status == .completed {
            TitleActions.markCompleted(title)
        }
        try? context.save()
        Haptics.success(settings.hapticsEnabled)
    }
}

/// A catalog grid card with an "added" check overlay.
private struct CatalogCard: View {
    let entry: CatalogEntry
    let added: Bool
    var intensity: AccentIntensity

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                CoverView(hue: Title.deterministicHue(for: entry.name),
                          kind: entry.kind,
                          initials: entry.name.coverInitials,
                          intensity: intensity)
                    .aspectRatio(3.0 / 4.0, contentMode: .fit)
                if added {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.white, Theme.good)
                        .padding(8)
                        .accessibilityLabel("Already in library")
                }
            }
            Text(entry.name)
                .font(Theme.rounded(14, .semibold))
                .foregroundStyle(Theme.ink)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            Text(entry.studioOrAuthor)
                .font(Theme.rounded(11))
                .foregroundStyle(Theme.inkSoft)
                .lineLimit(1)
            Pill(text: "\(entry.defaultUnits) \(entry.kind.unitNounPlural)",
                 systemImage: entry.kind.symbol, tint: Theme.violet)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.surface))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Theme.hairline, lineWidth: 1))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.name), \(entry.kind.rawValue)\(added ? ", already added" : "")")
    }
}
