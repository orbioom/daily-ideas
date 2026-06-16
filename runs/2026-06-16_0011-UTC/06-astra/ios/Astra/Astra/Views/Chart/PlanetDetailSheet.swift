import SwiftUI

/// Detail for a single placement: sign, house, degree, retrograde, interpretation.
struct PlanetDetailSheet: View {
    let planet: Planet
    let chart: Chart

    @Environment(\.dismiss) private var dismiss

    private var position: BodyPosition? { chart.position(planet) }
    private var house: House? { chart.house(for: planet) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    header
                    if let pos = position {
                        factGrid(pos: pos)
                        interpretationCard(pos: pos)
                        if let house {
                            houseCard(house)
                        }
                        roleCard
                    } else {
                        Text("Placement unavailable.")
                            .font(Theme.rounded(15))
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle(planet.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(Theme.inkFaint)
                    }
                    .accessibilityLabel("Close")
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text(planet.glyph)
                .font(.system(size: 52))
                .foregroundStyle(Theme.gold)
                .accessibilityHidden(true)
            if let pos = position {
                Text("\(planet.name) in \(pos.sign.name)")
                    .font(Theme.serif(22, .bold))
                    .foregroundStyle(Theme.ink)
                Text(planet.keywords.joined(separator: " · "))
                    .font(Theme.rounded(13, .semibold))
                    .foregroundStyle(Theme.inkFaint)
            }
        }
    }

    private func factGrid(pos: BodyPosition) -> some View {
        HStack(spacing: 10) {
            StatChip(caption: "Sign", value: pos.sign.name, tint: pos.sign.element.color)
            StatChip(caption: "Degree", value: ChartService.formatDegree(pos.degreesInSign))
            StatChip(caption: "House", value: house?.ordinal ?? "—")
            StatChip(caption: "Motion", value: pos.retrograde ? "Rx" : "Direct",
                     tint: pos.retrograde ? Theme.bad : Theme.good)
        }
    }

    private func interpretationCard(pos: BodyPosition) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "What this means", systemImage: "text.book.closed.fill")
            Text(planet.interpretation(in: pos.sign))
                .font(Theme.rounded(16))
                .foregroundStyle(Theme.ink)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
            if pos.retrograde {
                Text("Retrograde at birth: this energy turns inward — it's processed privately before it's expressed, and often re-examined throughout life.")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
                    .padding(.top, 4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .cardSurface()
    }

    private func houseCard(_ house: House) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "\(house.ordinal) House · \(house.title)", systemImage: "house.fill")
            Text(house.meaning)
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            Text("With \(planet.name) here, that part of life is colored by \(planet.keywords.first ?? "this") energy.")
                .font(Theme.rounded(14))
                .foregroundStyle(Theme.ink)
                .padding(.top, 2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .cardSurface()
    }

    private var roleCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "\(planet.name)'s role", systemImage: "sparkles")
            Text(planet.role)
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .cardSurface()
    }
}
