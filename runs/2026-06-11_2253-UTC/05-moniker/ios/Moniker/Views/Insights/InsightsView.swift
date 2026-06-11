import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Environment(\.colorScheme) private var scheme
    @Query private var verdicts: [Verdict]

    private var stats: MatchEngine.Stats { MatchEngine.stats(verdicts: verdicts) }

    var body: some View {
        NavigationStack {
            Group {
                if verdicts.isEmpty {
                    EmptyStateView(icon: "chart.pie",
                                   title: "Swipe to see your tastes",
                                   message: "Once you both start swiping, this tab shows your agreement rate, favorite name styles, and how your shortlist breaks down.")
                } else {
                    ScrollView {
                        VStack(spacing: 14) {
                            tiles
                            agreementCard
                            stylesCard
                            if !stats.matchGenderCounts.isEmpty {
                                genderCard
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(Theme.background(scheme))
            .navigationTitle("Insights")
        }
    }

    private var tiles: some View {
        HStack(spacing: 12) {
            tile(title: "Matches", value: "\(stats.matchCount)", color: Theme.blush)
            tile(title: "\(PartnerNames.name(.a)) liked", value: "\(stats.likedA)", color: Theme.blush)
            tile(title: "\(PartnerNames.name(.b)) liked", value: "\(stats.likedB)", color: Theme.sky)
        }
    }

    private func tile(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(Theme.inkSoft(scheme))
                .lineLimit(1)
            Text(value)
                .font(Theme.display(22))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Theme.card(scheme), in: RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .combine)
    }

    private var agreementCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("How aligned are you?").font(.headline)
            if let rate = stats.agreementRate {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(Int((rate * 100).rounded()))%")
                        .font(Theme.display(40))
                        .foregroundStyle(Theme.mint)
                    Text("agreement on names you've both judged")
                        .font(.subheadline)
                        .foregroundStyle(Theme.inkSoft(scheme))
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Theme.inkSoft(scheme).opacity(0.15))
                        Capsule().fill(Theme.mint)
                            .frame(width: max(geo.size.width * rate, 8))
                    }
                }
                .frame(height: 12)
                .accessibilityLabel("\(Int((rate * 100).rounded())) percent agreement")
            } else {
                Text("You both need to judge at least 5 of the same names before we can measure your agreement. Keep swiping!")
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSoft(scheme))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .monikerCard()
    }

    private var stylesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Favorite styles").font(.headline)
            styleColumn(title: PartnerNames.name(.a), data: stats.topStylesA, color: Theme.blush)
            Divider()
            styleColumn(title: PartnerNames.name(.b), data: stats.topStylesB, color: Theme.sky)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .monikerCard()
    }

    private func styleColumn(title: String, data: [(style: NameStyle, count: Int)], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(color)
            if data.isEmpty {
                Text("No likes yet.")
                    .font(.caption)
                    .foregroundStyle(Theme.inkSoft(scheme))
            } else {
                FlowWrap(spacing: 8) {
                    ForEach(data, id: \.style) { item in
                        Text("\(item.style.label) · \(item.count)")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(color.opacity(0.14), in: Capsule())
                            .foregroundStyle(color)
                    }
                }
            }
        }
    }

    private var genderCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Your shortlist").font(.headline)
            Chart(stats.matchGenderCounts, id: \.gender) { item in
                SectorMark(angle: .value("Count", item.count), innerRadius: .ratio(0.55))
                    .foregroundStyle(Theme.genderColor(item.gender))
                    .annotation(position: .overlay) {
                        Text("\(item.count)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                    }
            }
            .frame(height: 180)
            .accessibilityLabel("Matched names by gender")
            HStack(spacing: 16) {
                ForEach(stats.matchGenderCounts, id: \.gender) { item in
                    HStack(spacing: 5) {
                        Circle().fill(Theme.genderColor(item.gender)).frame(width: 9, height: 9)
                        Text("\(item.gender.label) (\(item.count))")
                            .font(.caption)
                            .foregroundStyle(Theme.inkSoft(scheme))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .monikerCard()
    }
}
