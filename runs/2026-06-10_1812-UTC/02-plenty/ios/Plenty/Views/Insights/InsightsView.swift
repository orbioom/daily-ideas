import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query private var days: [GratitudeDay]

    private var streak: Int { PlentyEngine.currentStreak(days: days) }
    private var entries: Int { PlentyEngine.entriesCount(days: days) }
    private var gratitudes: Int { PlentyEngine.totalGratitudes(days: days) }
    private var words: Int { PlentyEngine.totalWords(days: days) }
    private var avgMood: Double? { PlentyEngine.averageMood(days: days) }
    private var moodTrend: [(date: Date, mood: Int?)] { PlentyEngine.moodTrend(days: days, span: 30) }
    private var topWords: [(word: String, count: Int)] { PlentyEngine.topWords(days: days) }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if entries == 0 {
                    EmptyStateView(icon: "chart.bar",
                                   title: "Nothing to show yet",
                                   message: "Record a few days of gratitude and your patterns will appear here.")
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            statGrid
                            moodCard
                            if !topWords.isEmpty { wordsCard }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Insights")
        }
    }

    private var statGrid: some View {
        let cols = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
        return LazyVGrid(columns: cols, spacing: 12) {
            stat("Streak", "\(streak)", "leaf.fill", Brand.live)
            stat("Entries", "\(entries)", "calendar", Brand.info)
            stat("Gratitudes", "\(gratitudes)", "hands.sparkles.fill", Brand.warn)
            stat("Words", "\(words)", "text.alignleft", Brand.magic)
        }
    }

    private func stat(_ label: String, _ value: String, _ icon: String, _ color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundStyle(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.14), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(value).font(Brand.mono(20, weight: .semibold)).foregroundStyle(Brand.text)
                Text(label).font(Brand.mono(10)).foregroundStyle(Brand.text3)
            }
            Spacer()
        }
        .glassCard(padding: 12)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(value)")
    }

    private var moodCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Eyebrow(text: "Mood · last 30 days")
                Spacer()
                if let avg = avgMood {
                    Text("avg \(avg, specifier: "%.1f")").font(Brand.mono(12)).foregroundStyle(Brand.text3)
                }
            }
            Chart {
                ForEach(moodTrend.filter { $0.mood != nil }, id: \.date) { item in
                    LineMark(x: .value("Day", item.date, unit: .day),
                             y: .value("Mood", item.mood ?? 0))
                    .foregroundStyle(Brand.live.gradient)
                    .interpolationMethod(.catmullRom)
                    PointMark(x: .value("Day", item.date, unit: .day),
                              y: .value("Mood", item.mood ?? 0))
                    .foregroundStyle(Brand.live)
                }
            }
            .frame(height: 150)
            .chartYScale(domain: 1...5)
            .chartYAxis { AxisMarks(values: [1, 3, 5]) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    private var wordsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow(text: "What you're grateful for")
            FlowWords(words: topWords)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }
}

/// Simple wrapping tag cloud sized by frequency.
struct FlowWords: View {
    let words: [(word: String, count: Int)]
    private var maxCount: Int { words.map { $0.count }.max() ?? 1 }

    var body: some View {
        FlexLayout(spacing: 8) {
            ForEach(words, id: \.word) { item in
                let scale = Double(item.count) / Double(maxCount)
                Text(item.word)
                    .font(.system(size: 14 + CGFloat(scale * 10), weight: .medium))
                    .foregroundStyle(Brand.text)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Brand.magic.opacity(0.12 + scale * 0.18),
                                in: Capsule())
            }
        }
    }
}

/// A minimal flow layout for wrapping chips.
struct FlexLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rows: [[CGSize]] = [[]]
        var x: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                rows.append([])
                x = 0
            }
            rows[rows.count - 1].append(size)
            x += size.width + spacing
        }
        let height = rows.reduce(0) { acc, row in
            acc + (row.map { $0.height }.max() ?? 0) + spacing
        }
        return CGSize(width: maxWidth == .infinity ? x : maxWidth, height: max(0, height - spacing))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            sub.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
