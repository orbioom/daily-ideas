import SwiftUI
import SwiftData

/// Pushed detail screen for one country: large flag, key facts, mastery, star.
struct CountryDetailView: View {
    let country: Country

    @Environment(\.modelContext) private var modelContext
    @Query private var progress: [CountryProgress]

    private var record: CountryProgress? {
        progress.first { $0.iso2 == country.iso2 }
    }
    private var starred: Bool { record?.starred ?? false }
    private var mastery: Double { record?.mastery ?? 0 }
    private var level: MasteryLevel { record?.level ?? .unseen }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                flagHeader
                masteryCard
                detailGrid
                factsCard
            }
            .padding(20)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle(country.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Haptics.tap()
                    ProgressStore(context: modelContext).toggleStar(country.iso2)
                } label: {
                    Image(systemName: starred ? "star.fill" : "star")
                        .foregroundStyle(Theme.accent)
                }
                .accessibilityLabel(starred ? "Remove star" : "Star this country")
            }
        }
    }

    private var flagHeader: some View {
        GlassCard(padding: 24) {
            VStack(spacing: 10) {
                Text(country.flag)
                    .font(.system(size: 96))
                    .accessibilityHidden(true)
                Text(country.name)
                    .font(Theme.rounded(26, .bold))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                Label(country.continent.title, systemImage: country.continent.systemImage)
                    .font(Theme.rounded(14, .semibold))
                    .foregroundStyle(country.continent.tint)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var masteryCard: some View {
        GlassCard {
            HStack(spacing: 16) {
                MasteryRing(progress: mastery, lineWidth: 9,
                            label: "\(Int(mastery * 100))%")
                    .frame(width: 64, height: 64)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your mastery")
                        .font(Theme.rounded(15, .medium))
                        .foregroundStyle(Theme.inkSoft)
                    Text(level.label)
                        .font(Theme.rounded(19, .bold))
                        .foregroundStyle(Theme.ink)
                    if let r = record, r.seen > 0 {
                        Text("\(r.correct) of \(r.seen) answered correctly")
                            .font(Theme.rounded(12))
                            .foregroundStyle(Theme.inkSoft)
                    } else {
                        Text("Not practiced yet")
                            .font(Theme.rounded(12))
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
                Spacer()
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var detailGrid: some View {
        GlassCard {
            VStack(spacing: 0) {
                detailRow("Capital", country.capital, icon: "building.2")
                Divider().overlay(Theme.hairline)
                detailRow("Region", country.region, icon: "map")
                Divider().overlay(Theme.hairline)
                detailRow("Population", "≈ \(country.populationText)", icon: "person.3")
                Divider().overlay(Theme.hairline)
                detailRow("Currency", country.currency, icon: "banknote")
            }
        }
    }

    private func detailRow(_ label: String, _ value: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(Theme.accent)
                .frame(width: 22)
            Text(label)
                .font(Theme.rounded(15, .medium))
                .foregroundStyle(Theme.inkSoft)
            Spacer()
            Text(value)
                .font(Theme.rounded(15, .semibold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    private var factsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("Did you know?", systemImage: "lightbulb")
                    .font(Theme.rounded(16, .bold))
                    .foregroundStyle(Theme.ink)
                ForEach(Array(country.facts.enumerated()), id: \.offset) { _, fact in
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(Theme.accent)
                            .frame(width: 6, height: 6)
                            .padding(.top, 7)
                            .accessibilityHidden(true)
                        Text(fact)
                            .font(Theme.rounded(15))
                            .foregroundStyle(Theme.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
