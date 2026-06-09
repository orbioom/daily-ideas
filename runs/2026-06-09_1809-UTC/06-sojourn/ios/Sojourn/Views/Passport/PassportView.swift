import SwiftUI
import SwiftData

struct PassportView: View {
    @Query private var marks: [VisitMark]
    @AppStorage("sojourn.countTransit") private var countTransit = false
    @AppStorage("sojourn.homeCode") private var homeCode = ""

    @State private var selected: Country?

    private var home: String? { homeCode.isEmpty ? nil : homeCode }

    private var progress: SojournEngine.WorldProgress {
        SojournEngine.worldProgress(marks, countTransit: countTransit, homeCode: home)
    }
    private var continents: [SojournEngine.ContinentProgress] {
        SojournEngine.continentBreakdown(marks, countTransit: countTransit, homeCode: home)
    }
    private var statusCounts: [VisitStatus: Int] { SojournEngine.statusCounts(marks) }
    private var recent: [VisitMark] { SojournEngine.recentMarks(marks, limit: 6) }

    private var percentText: String {
        "\(Int((progress.percent * 100).rounded()))%"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if progress.groundedCount == 0 {
                    emptyState
                } else {
                    VStack(spacing: 18) {
                        heroCard
                        statusTiles
                        continentCard
                        if !recent.isEmpty { recentCard }
                    }
                    .padding(20)
                }
            }
            .background(Brand.pageBackground)
            .navigationTitle("Passport")
            .sheet(item: $selected) { CountryDetailView(country: $0) }
        }
    }

    // MARK: Empty

    private var emptyState: some View {
        VStack(spacing: 20) {
            EmptyStateView(icon: "globe.europe.africa",
                           title: "Your passport is waiting",
                           message: "Mark the first country you've been to and watch your map of the world begin to fill in.")
            NavigationLink {
                BrowseCountriesView()
            } label: {
                Label("Mark your first country", systemImage: "map")
            }
            .buttonStyle(InkButtonStyle())
        }
        .glassCard()
        .padding(20)
    }

    // MARK: Hero

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Eyebrow(text: "World progress")
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(progress.groundedCount)")
                    .font(Brand.mono(52, weight: .bold))
                    .foregroundStyle(Brand.text)
                Text("/ \(progress.total) countries")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(Brand.text2)
            }
            ProgressView(value: progress.percent) {
                Text("\(percentText) of the world")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Brand.text2)
            }
            .tint(Brand.magic)

            HStack(spacing: 8) {
                Image(systemName: "globe")
                    .foregroundStyle(Brand.info)
                    .accessibilityHidden(true)
                Text("\(progress.continentsTouched) of \(progress.continentTotal) continents touched")
                    .font(.subheadline)
                    .foregroundStyle(Brand.text2)
            }
            .accessibilityElement(children: .combine)
        }
        .glassCard()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("World progress")
        .accessibilityValue("\(progress.groundedCount) of \(progress.total) countries, \(percentText) of the world, \(progress.continentsTouched) of \(progress.continentTotal) continents")
    }

    // MARK: Status tiles

    private var statusTiles: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatTile(value: "\(statusCounts[.visited] ?? 0)", label: "Visited", tint: VisitStatus.visited.tint)
            StatTile(value: "\(statusCounts[.lived] ?? 0)", label: "Lived", tint: VisitStatus.lived.tint)
            StatTile(value: "\(statusCounts[.wishlist] ?? 0)", label: "Wishlist", tint: VisitStatus.wishlist.tint)
        }
    }

    // MARK: Continents

    private var continentCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "By continent")
            ForEach(continents) { c in
                RankBar(title: c.continent.label,
                        detail: "\(c.grounded) / \(c.total)",
                        fraction: c.fraction,
                        tint: c.continent.tint)
            }
        }
        .glassCard()
    }

    // MARK: Recent

    private var recentCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: "Recent additions")
            ForEach(recent) { mark in
                if let country = mark.country {
                    Button {
                        Haptics.tap()
                        selected = country
                    } label: {
                        CountryRow(country: country, status: mark.status, isFavorite: mark.isFavorite)
                    }
                    .buttonStyle(.plain)
                    if mark.id != recent.last?.id {
                        Divider().overlay(Brand.hairline)
                    }
                }
            }
        }
        .glassCard()
    }
}
