import SwiftUI
import SwiftData

/// Search any star, planet or constellation → where is it now, plus favourites.
struct SearchView: View {
    @Bindable var sky: SkyViewModel
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Query(sort: \FavoriteObject.addedAt, order: .reverse) private var favorites: [FavoriteObject]

    @State private var query = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                content
            }
            .navigationTitle("Search")
            .searchable(text: $query, prompt: "Star, planet or constellation")
            .autocorrectionDisabled()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch sky.state {
        case .idle, .loading:
            LoadingView(message: "Preparing the catalogue…")
        case .failed(let message):
            ErrorStateView(message: message) {
                Task { await sky.refresh(settings: settings, isPro: isPro) }
            }
        case .loaded(let snap):
            results(snap)
        }
    }

    private func results(_ snap: SkySnapshot) -> some View {
        let matches = search(snap)
        return List {
            if query.isEmpty {
                favoritesSection(snap)
                browseSection(snap)
            } else if matches.isEmpty {
                Section {
                    EmptyStateView(symbol: "magnifyingglass",
                                   title: "No matches",
                                   message: "Try a star like ‘Vega’, a planet like ‘Mars’, or a constellation like ‘Orion’.")
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                }
            } else {
                Section("Results") {
                    ForEach(matches) { item in
                        resultRow(item, snap: snap)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
    }

    @ViewBuilder
    private func favoritesSection(_ snap: SkySnapshot) -> some View {
        if favorites.isEmpty {
            Section("Favourites") {
                EmptyStateView(symbol: "star",
                               title: "No favourites yet",
                               message: "Tap the star on any object to keep it here for quick checks.")
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
            }
        } else {
            Section("Favourites") {
                ForEach(favorites) { fav in
                    if let obj = resolve(fav.identifier, snap: snap) {
                        resultRow(SearchItem(object: obj), snap: snap)
                    } else {
                        Text(fav.name).foregroundStyle(Theme.inkSoft)
                            .listRowBackground(Theme.surface)
                    }
                }
            }
        }
    }

    private func browseSection(_ snap: SkySnapshot) -> some View {
        Section("Browse") {
            ForEach(snap.planets.filter { $0.kind == .planet || $0.kind == .moon }) { p in
                resultRow(SearchItem(object: p), snap: snap)
            }
        }
    }

    private func resultRow(_ item: SearchItem, snap: SkySnapshot) -> some View {
        NavigationLink {
            ObjectDetailView(object: item.object, context: snap.context)
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(item.object.tint.opacity(0.2)).frame(width: 36, height: 36)
                    Image(systemName: item.object.kind.symbol).font(.caption).foregroundStyle(item.object.tint)
                        .accessibilityHidden(true)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.object.name).font(Theme.rounded(16, .semibold)).foregroundStyle(Theme.ink)
                    Text(whereLine(item.object)).font(.caption).foregroundStyle(statusColor(item.object))
                }
                Spacer()
                Image(systemName: item.object.isAboveHorizon ? "eye" : "eye.slash")
                    .font(.caption)
                    .foregroundStyle(item.object.isAboveHorizon ? Theme.good : Theme.inkFaint)
            }
        }
        .listRowBackground(Theme.surface)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.object.name). \(whereLine(item.object)).")
    }

    private func whereLine(_ o: SkyObject) -> String {
        if o.isAboveHorizon {
            return "Up now • \(o.horizontal.compass16) • \(Fmt.altitude(o.horizontal.altitude))"
        }
        return "Below the horizon"
    }

    private func statusColor(_ o: SkyObject) -> Color {
        o.isAboveHorizon ? Theme.good : Theme.inkSoft
    }

    // MARK: - Search model

    struct SearchItem: Identifiable {
        let object: SkyObject
        var id: String { object.id }
    }

    private func search(_ snap: SkySnapshot) -> [SearchItem] {
        let q = query.lowercased().trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return [] }
        var items: [SearchItem] = []

        // Planets / Sun / Moon.
        for p in snap.planets where p.name.lowercased().contains(q) {
            items.append(SearchItem(object: p))
        }
        // Stars by name, Bayer, or constellation.
        for s in snap.stars {
            let star = Catalog.starByID[s.starID ?? -1]
            let bayer = star?.bayer.lowercased() ?? ""
            if s.name.lowercased().contains(q) || s.constellation.lowercased().contains(q) || bayer.contains(q) {
                items.append(SearchItem(object: s))
            }
        }
        // Sort: above-horizon first, then by brightness.
        items.sort { a, b in
            if a.object.isAboveHorizon != b.object.isAboveHorizon {
                return a.object.isAboveHorizon
            }
            return a.object.magnitude < b.object.magnitude
        }
        return Array(items.prefix(60))
    }

    private func resolve(_ id: String, snap: SkySnapshot) -> SkyObject? {
        (snap.planets + snap.stars).first { $0.id == id }
    }
}
