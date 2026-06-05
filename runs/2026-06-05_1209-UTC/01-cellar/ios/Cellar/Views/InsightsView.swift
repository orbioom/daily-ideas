import SwiftUI
import SwiftData

/// A calm dashboard of what the cellar reveals about your palate.
struct InsightsView: View {
    @Query private var bottles: [Bottle]

    private var insights: CellarModel.Insights {
        CellarModel.insights(for: bottles)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if bottles.isEmpty {
                    EmptyStateView(
                        icon: "chart.bar",
                        title: "No insights yet",
                        message: "Add bottles and record tastings — your favorites, streak and flavor patterns will appear here."
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            summaryRow
                            if !insights.byCategory.isEmpty { categoryCard }
                            if let best = insights.highestRated { highestCard(best) }
                            if !insights.topFlavors.isEmpty { flavorsCard }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Insights")
        }
    }

    private var summaryRow: some View {
        HStack(spacing: 12) {
            statTile(value: "\(insights.bottleCount)", label: "Bottles")
            statTile(value: "\(insights.tastingCount)", label: "Tastings")
            statTile(
                value: insights.averageRating.map { String(format: "%.1f", $0) } ?? "—",
                label: "Avg rating"
            )
        }
    }

    private func statTile(value: String, label: String) -> some View {
        GlassCard {
            VStack(spacing: 4) {
                Text(value).font(Brand.mono(24, weight: .bold)).foregroundStyle(Brand.text)
                Text(label).font(.caption).foregroundStyle(Brand.text3)
            }
            .frame(maxWidth: .infinity)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label), \(value)")
    }

    private var categoryCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                cardTitle("By category")
                let maxCount = max(1, insights.byCategory.map(\.count).max() ?? 1)
                ForEach(insights.byCategory, id: \.category) { item in
                    HStack(spacing: 10) {
                        Image(systemName: item.category.symbol)
                            .font(.footnote)
                            .foregroundStyle(item.category.tint)
                            .frame(width: 22)
                        Text(item.category.title).font(.subheadline).foregroundStyle(Brand.text)
                            .frame(width: 70, alignment: .leading)
                        GeometryReader { geo in
                            Capsule()
                                .fill(item.category.tint.opacity(0.85))
                                .frame(width: max(6, geo.size.width * CGFloat(item.count) / CGFloat(maxCount)))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(height: 12)
                        Text("\(item.count)")
                            .font(Brand.mono(14, weight: .semibold)).foregroundStyle(Brand.text2)
                            .frame(width: 24, alignment: .trailing)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(item.category.title), \(item.count) bottle\(item.count == 1 ? "" : "s")")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func highestCard(_ bottle: Bottle) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                cardTitle("Highest rated")
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(bottle.name).font(.headline).foregroundStyle(Brand.text)
                        if !bottle.producer.isEmpty {
                            Text(bottle.producer).font(.subheadline).foregroundStyle(Brand.text2)
                        }
                    }
                    Spacer()
                    if let avg = bottle.averageRating {
                        VStack(spacing: 2) {
                            Text(String(format: "%.1f", avg))
                                .font(Brand.mono(22, weight: .bold))
                                .foregroundStyle(Brand.text)
                            RatingDisplay(value: avg)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var flavorsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    cardTitle("Flavors you reach for")
                    Spacer()
                    if insights.currentStreakDays > 0 {
                        HStack(spacing: 5) {
                            Circle().fill(Brand.live).frame(width: 7, height: 7)
                            Text("\(insights.currentStreakDays)-day streak")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Brand.text2)
                        }
                        .accessibilityLabel("Current streak, \(insights.currentStreakDays) days")
                    }
                }
                FlowLayout(spacing: 8) {
                    ForEach(insights.topFlavors, id: \.name) { flavor in
                        HStack(spacing: 6) {
                            Text(flavor.name).font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Brand.text)
                            Text("\(flavor.count)")
                                .font(Brand.mono(12, weight: .semibold))
                                .foregroundStyle(Brand.text3)
                        }
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .background(.ultraThinMaterial, in: Capsule())
                        .overlay(Capsule().strokeBorder(Brand.glassStroke.opacity(0.5), lineWidth: 1))
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(flavor.name), noted \(flavor.count) time\(flavor.count == 1 ? "" : "s")")
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func cardTitle(_ text: String) -> some View {
        Text(text).font(.headline).foregroundStyle(Brand.text)
    }
}
