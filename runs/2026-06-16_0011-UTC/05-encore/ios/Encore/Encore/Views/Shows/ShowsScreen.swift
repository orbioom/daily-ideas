import SwiftUI
import SwiftData

/// The full searchable / filterable library of attended shows.
struct ShowsScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Query(sort: \Concert.date, order: .reverse) private var concerts: [Concert]
    @Query private var allGenres: [Genre]

    @State private var searchText = ""
    @State private var sort: ShowSort = .dateNewest
    @State private var yearFilter: Int?
    @State private var genreFilter: String?
    @State private var showEditor = false
    @State private var paywallReason: PaywallReason?
    @State private var didLoadDefaultSort = false

    private var attended: [Concert] {
        concerts.filter { $0.status == .attended }
    }

    private var availableYears: [Int] {
        Array(Set(attended.map { $0.year })).sorted(by: >)
    }

    private var availableGenres: [String] {
        var seen = Set<String>()
        var names: [String] = []
        for c in attended {
            for g in c.genres {
                let key = g.name.lowercased()
                guard !seen.contains(key) else { continue }
                seen.insert(key)
                names.append(g.name)
            }
        }
        return names.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    private var hasActiveFilter: Bool {
        yearFilter != nil || genreFilter != nil
    }

    private var filtered: [Concert] {
        var list = attended

        if let yearFilter { list = list.filter { $0.year == yearFilter } }
        if let genreFilter {
            list = list.filter { c in
                c.genres.contains { $0.name.lowercased() == genreFilter.lowercased() }
            }
        }

        let q = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        if !q.isEmpty {
            list = list.filter { c in
                c.headliner.lowercased().contains(q) ||
                c.venueName.lowercased().contains(q) ||
                c.city.lowercased().contains(q) ||
                c.tourName.lowercased().contains(q) ||
                c.supportActs.contains { $0.name.lowercased().contains(q) } ||
                c.genres.contains { $0.name.lowercased().contains(q) }
            }
        }

        switch sort {
        case .dateNewest: list.sort { $0.date > $1.date }
        case .dateOldest: list.sort { $0.date < $1.date }
        case .artist: list.sort { $0.headliner.localizedCaseInsensitiveCompare($1.headliner) == .orderedAscending }
        case .rating: list.sort { ($0.rating ?? -1) > ($1.rating ?? -1) }
        case .venue: list.sort { $0.venueName.localizedCaseInsensitiveCompare($1.venueName) == .orderedAscending }
        }
        return list
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Theme.bg.ignoresSafeArea()
                content
                addButton
            }
            .navigationTitle("Shows")
            .toolbar { toolbarContent }
            .searchable(text: $searchText, prompt: "Artist, venue, city, support…")
            .navigationDestination(for: Concert.self) { c in
                ConcertDetailView(concert: c, allGenres: allGenres)
            }
            .sheet(isPresented: $showEditor) {
                ConcertEditorView(concert: nil, allGenres: allGenres)
            }
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
        }
        .onAppear {
            guard !didLoadDefaultSort else { return }
            sort = settings.defaultSort
            didLoadDefaultSort = true
        }
    }

    @ViewBuilder
    private var content: some View {
        if attended.isEmpty {
            EmptyStateView(symbol: "music.note.list",
                           title: "No shows logged",
                           message: "Once you log a show it lands here — searchable by artist, venue, city, or support act.",
                           actionTitle: "Log a show") { presentEditor() }
        } else if filtered.isEmpty {
            EmptyStateView(symbol: "magnifyingglass",
                           title: "No matches",
                           message: "Nothing fits that search or filter. Try clearing it.",
                           actionTitle: "Clear filters") { clearFilters() }
        } else {
            List {
                ForEach(filtered) { c in
                    NavigationLink(value: c) {
                        ShowRow(concert: c)
                    }
                    .listRowBackground(Theme.bg)
                    .listRowSeparator(.hidden)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) { delete(c) } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        Button {
                            c.isFavorite.toggle()
                            try? context.save()
                            Haptics.tap(enabled: settings.hapticsEnabled)
                        } label: {
                            Label(c.isFavorite ? "Unfavorite" : "Favorite",
                                  systemImage: c.isFavorite ? "heart.slash" : "heart")
                        }
                        .tint(Theme.accent)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Picker("Sort", selection: $sort) {
                    ForEach(ShowSort.allCases) { s in
                        Label(s.rawValue, systemImage: s.symbol).tag(s)
                    }
                }
                Menu("Year") {
                    Button("All years") { yearFilter = nil }
                    ForEach(availableYears, id: \.self) { y in
                        Button {
                            yearFilter = (yearFilter == y) ? nil : y
                        } label: {
                            if yearFilter == y {
                                Label(String(y), systemImage: "checkmark")
                            } else {
                                Text(String(y))
                            }
                        }
                    }
                }
                Menu("Genre") {
                    Button("All genres") { genreFilter = nil }
                    ForEach(availableGenres, id: \.self) { name in
                        Button {
                            genreFilter = (genreFilter == name) ? nil : name
                        } label: {
                            if genreFilter == name {
                                Label(name, systemImage: "checkmark")
                            } else {
                                Text(name)
                            }
                        }
                    }
                }
                if hasActiveFilter {
                    Divider()
                    Button(role: .destructive) { clearFilters() } label: {
                        Label("Clear filters", systemImage: "xmark.circle")
                    }
                }
            } label: {
                Image(systemName: hasActiveFilter
                      ? "line.3.horizontal.decrease.circle.fill"
                      : "line.3.horizontal.decrease.circle")
            }
            .accessibilityLabel("Sort and filter")
        }
    }

    private var addButton: some View {
        Button {
            presentEditor()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 58, height: 58)
                .background(Circle().fill(Theme.heroGradient))
                .shadow(color: Theme.accent.opacity(0.4), radius: 10, y: 4)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 20)
        .accessibilityLabel("Log a show")
    }

    private func presentEditor() {
        if !Pro.canAddShow(currentCount: concerts.count, isPro: isPro) {
            paywallReason = .showLimit
            Haptics.warning(enabled: settings.hapticsEnabled)
            return
        }
        Haptics.tap(enabled: settings.hapticsEnabled)
        showEditor = true
    }

    private func clearFilters() {
        yearFilter = nil
        genreFilter = nil
        searchText = ""
    }

    private func delete(_ c: Concert) {
        context.delete(c)
        try? context.save()
        Haptics.tap(enabled: settings.hapticsEnabled)
    }
}

/// A compact row for the Shows list.
struct ShowRow: View {
    let concert: Concert

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Theme.ticketGradient(seed: concert.colorSeed))
                .frame(width: 46, height: 46)
                .overlay(
                    Image(systemName: concert.type.symbol)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                )
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(concert.headliner)
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                Text(subtitle)
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
                    .lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                if concert.isFavorite {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.accent)
                        .accessibilityHidden(true)
                }
                if let rating = concert.rating {
                    RatingStarsDisplay(rating: rating, size: 10)
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(concert.headliner), \(subtitle)\(concert.rating.map { String(format: ", rated %.1f", $0) } ?? "")")
    }

    private var subtitle: String {
        var parts: [String] = []
        if !concert.locationLine.isEmpty { parts.append(concert.locationLine) }
        parts.append(concert.date.formatted(date: .abbreviated, time: .omitted))
        return parts.joined(separator: " · ")
    }
}

#Preview("Shows") {
    ShowsScreen()
        .environmentObject(AppSettings())
        .modelContainer(PreviewContainer.shared)
}
