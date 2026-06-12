import SwiftUI
import SwiftData
import Charts

private struct OriginCount: Identifiable {
    let id: String   // origin
    let count: Int
}

private struct StyleCount: Identifiable {
    let id: String   // style display name
    let count: Int
}

struct InsightsView: View {
    @Query private var decisions: [Decision]

    @AppStorage("partnerAName") private var partnerAName = "Partner A"
    @AppStorage("partnerBName") private var partnerBName = "Partner B"

    private var matches: [NameEntry] { MatchEngine.matches(in: decisions) }

    private var likedEntries: [NameEntry] {
        let liked = MatchEngine.likedIDs(for: .a, in: decisions)
            .union(MatchEngine.likedIDs(for: .b, in: decisions))
        return liked.compactMap { NameCatalog.entry(id: $0) }
    }

    private var originCounts: [OriginCount] {
        let groups = Dictionary(grouping: likedEntries, by: \.origin)
        return groups.map { OriginCount(id: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
            .prefix(8)
            .map { $0 }
    }

    private var styleCounts: [StyleCount] {
        var counts: [NameStyle: Int] = [:]
        for entry in likedEntries {
            for style in entry.styles {
                counts[style, default: 0] += 1
            }
        }
        return counts.map { StyleCount(id: $0.key.displayName, count: $0.value) }
            .sorted { $0.count > $1.count }
            .prefix(6)
            .map { $0 }
    }

    var body: some View {
        NavigationStack {
            Group {
                if decisions.isEmpty {
                    ContentUnavailableView(
                        "Nothing to Analyze Yet",
                        systemImage: "chart.pie",
                        description: Text("Swipe a few names and Moniker will show your shared taste — favorite origins, styles, and how often you agree.")
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            summaryTiles
                            agreementPanel
                            chartPanel(
                                title: "Origins You Love",
                                empty: "Love some names to see your favorite origins."
                            ) {
                                Chart(originCounts) { item in
                                    BarMark(
                                        x: .value("Names", item.count),
                                        y: .value("Origin", item.id)
                                    )
                                    .foregroundStyle(MonikerTheme.rose.gradient)
                                    .cornerRadius(3)
                                }
                                .frame(height: max(160, CGFloat(originCounts.count) * 34))
                                .accessibilityLabel("Bar chart of loved names by origin")
                            }
                            chartPanel(
                                title: "Styles You Lean Toward",
                                empty: "Style tags of loved names appear here."
                            ) {
                                Chart(styleCounts) { item in
                                    BarMark(
                                        x: .value("Names", item.count),
                                        y: .value("Style", item.id)
                                    )
                                    .foregroundStyle(MonikerTheme.sky.gradient)
                                    .cornerRadius(3)
                                }
                                .frame(height: max(140, CGFloat(styleCounts.count) * 34))
                                .accessibilityLabel("Bar chart of loved names by style")
                            }
                        }
                        .padding()
                    }
                    .background(Color(.systemGroupedBackground))
                }
            }
            .navigationTitle("Insights")
        }
    }

    private var summaryTiles: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            tile("Matches", value: "\(matches.count)", icon: "heart.fill", color: MonikerTheme.roseDeep)
            tile(partnerAName, value: "\(MatchEngine.decidedIDs(for: .a, in: decisions).count)", icon: "person.fill", color: MonikerTheme.sky, caption: "swiped")
            tile(partnerBName, value: "\(MatchEngine.decidedIDs(for: .b, in: decisions).count)", icon: "person.fill", color: MonikerTheme.rose, caption: "swiped")
        }
    }

    private func tile(_ title: String, value: String, icon: String, color: Color, caption: String? = nil) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
            Text(value)
                .font(.title3.weight(.semibold))
            Text(caption.map { "\(title) \($0)" } ?? title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var agreementPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Taste Agreement")
                .font(.headline)
            if let rate = MatchEngine.agreementRate(in: decisions) {
                HStack(alignment: .lastTextBaseline, spacing: 8) {
                    Text(rate.formatted(.percent.precision(.fractionLength(0))))
                        .font(.system(size: 40, weight: .semibold, design: .rounded))
                        .foregroundStyle(MonikerTheme.roseDeep)
                    Text("of names you've both seen, you agree on")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                ProgressView(value: rate)
                    .tint(MonikerTheme.roseDeep)
            } else {
                Text("Once you've both swiped some of the same names, your agreement rate appears here.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .monikerPanel()
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func chartPanel<Content: View>(
        title: String,
        empty: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            if likedEntries.isEmpty {
                Text(empty)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 18)
            } else {
                content()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .monikerPanel()
    }
}
