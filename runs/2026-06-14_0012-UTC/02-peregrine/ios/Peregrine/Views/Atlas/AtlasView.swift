import SwiftUI
import SwiftData

/// Browse all countries, grouped by continent, with search and star toggles.
/// Tapping a row pushes the Country Detail screen.
struct AtlasView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var progress: [CountryProgress]

    @State private var search = ""
    @State private var starredOnly = false

    private var starredSet: Set<String> {
        Set(progress.filter { $0.starred }.map { $0.iso2 })
    }
    private var masteryByISO: [String: MasteryLevel] {
        Dictionary(progress.map { ($0.iso2, $0.level) }, uniquingKeysWith: { a, _ in a })
    }

    private var filtered: [Country] {
        let q = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return CountryData.all.filter { country in
            if starredOnly && !starredSet.contains(country.iso2) { return false }
            guard !q.isEmpty else { return true }
            return country.name.lowercased().contains(q)
                || country.capital.lowercased().contains(q)
        }
    }

    private var grouped: [(continent: Continent, items: [Country])] {
        Continent.displayOrder.compactMap { c in
            let items = filtered.filter { $0.continent == c }
            return items.isEmpty ? nil : (c, items)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if grouped.isEmpty {
                    EmptyStateView(systemImage: starredOnly ? "star" : "magnifyingglass",
                                   title: starredOnly ? "No starred countries" : "No matches",
                                   message: starredOnly
                                       ? "Star countries from their detail page to build a study list."
                                       : "Try a different name or capital.")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Theme.bg)
                } else {
                    List {
                        ForEach(grouped, id: \.continent) { section in
                            Section {
                                ForEach(section.items) { country in
                                    NavigationLink(value: country) {
                                        CountryRow(country: country,
                                                   level: masteryByISO[country.iso2] ?? .unseen,
                                                   starred: starredSet.contains(country.iso2))
                                    }
                                    .listRowBackground(Theme.surface)
                                }
                            } header: {
                                Label(section.continent.title, systemImage: section.continent.systemImage)
                                    .font(Theme.rounded(14, .bold))
                                    .foregroundStyle(section.continent.tint)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .background(Theme.bg)
                }
            }
            .navigationTitle("Atlas")
            .navigationDestination(for: Country.self) { CountryDetailView(country: $0) }
            .searchable(text: $search, prompt: "Country or capital")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.tap()
                        starredOnly.toggle()
                    } label: {
                        Image(systemName: starredOnly ? "star.fill" : "star")
                            .foregroundStyle(Theme.accent)
                    }
                    .accessibilityLabel(starredOnly ? "Show all countries" : "Show starred only")
                }
            }
        }
    }
}

/// A single country row in the Atlas list.
private struct CountryRow: View {
    let country: Country
    let level: MasteryLevel
    let starred: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text(country.flag)
                .font(.system(size: 30))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(country.name)
                        .font(Theme.rounded(16, .semibold))
                        .foregroundStyle(Theme.ink)
                    if starred {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(Theme.accent)
                            .accessibilityHidden(true)
                    }
                }
                Text(country.capital)
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
            }
            Spacer()
            MasteryDot(level: level)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(country.name), capital \(country.capital)")
        .accessibilityValue("\(level.label)\(starred ? ", starred" : "")")
    }
}

/// Small colored dot indicating mastery level.
struct MasteryDot: View {
    let level: MasteryLevel
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 10, height: 10)
            .overlay(Circle().strokeBorder(Theme.hairline, lineWidth: level == .unseen ? 1 : 0))
            .accessibilityHidden(true)
    }
    private var color: Color {
        switch level {
        case .unseen: return Theme.surfaceAlt
        case .learning: return Theme.bad
        case .familiar: return Theme.accent
        case .mastered: return Theme.good
        }
    }
}

#Preview {
    AtlasView()
        .modelContainer(for: [CountryProgress.self, QuizSession.self], inMemory: true)
}
