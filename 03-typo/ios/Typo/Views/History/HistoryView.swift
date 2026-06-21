import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \TypoResult.date, order: .reverse) private var results: [TypoResult]
    @Environment(\.modelContext) private var modelContext
    @State private var selectedMode: String? = nil

    var filtered: [TypoResult] {
        guard let m = selectedMode else { return results }
        return results.filter { $0.mode == m }
    }

    var body: some View {
        ZStack {
            TypoTheme.background.ignoresSafeArea()
            if results.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        statsOverview
                        modeFilter
                        wpmChart
                        resultsList
                    }
                    .padding(16)
                }
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(TypoTheme.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 52))
                .foregroundStyle(TypoTheme.textSecondary)
            Text("No Tests Yet")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(TypoTheme.textPrimary)
            Text("Complete a typing test to see your stats here.")
                .font(.system(size: 15))
                .foregroundStyle(TypoTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    var statsOverview: some View {
        let best = results.max(by: { $0.wpm < $1.wpm })
        let avg = results.isEmpty ? 0 : results.reduce(0) { $0 + $1.wpm } / Double(results.count)
        let avgAcc = results.isEmpty ? 0 : results.reduce(0) { $0 + $1.accuracy } / Double(results.count)
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            statCard(value: "\(Int(best?.wpm ?? 0))", label: "Best WPM", color: TypoTheme.accentPurple)
            statCard(value: "\(Int(avg))", label: "Avg WPM", color: TypoTheme.accent)
            statCard(value: "\(Int(avgAcc))%", label: "Avg Acc", color: TypoTheme.correctGreen)
        }
    }

    func statCard(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(TypoTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(TypoTheme.surface, in: RoundedRectangle(cornerRadius: 12))
    }

    var modeFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(label: "All", mode: nil)
                ForEach(TypingMode.allCases, id: \.self) { mode in
                    filterChip(label: mode.rawValue, mode: mode.rawValue)
                }
            }
        }
    }

    func filterChip(label: String, mode: String?) -> some View {
        Button {
            withAnimation { selectedMode = mode }
        } label: {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(selectedMode == mode ? .black : TypoTheme.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    selectedMode == mode ? TypoTheme.accent : TypoTheme.surface,
                    in: Capsule()
                )
        }
    }

    var wpmChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("WPM Over Time")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(TypoTheme.textSecondary)
            WpmSparkline(results: Array(filtered.reversed().prefix(20)))
                .frame(height: 80)
        }
        .padding(14)
        .background(TypoTheme.surface, in: RoundedRectangle(cornerRadius: 14))
    }

    var resultsList: some View {
        VStack(spacing: 8) {
            ForEach(filtered.prefix(50)) { result in
                ResultRow(result: result)
            }
        }
    }
}

struct WpmSparkline: View {
    let results: [TypoResult]

    var body: some View {
        GeometryReader { geo in
            guard results.count > 1 else {
                return AnyView(
                    Text("Not enough data")
                        .font(.system(size: 12))
                        .foregroundStyle(TypoTheme.textSecondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                )
            }
            let maxWpm = results.map { $0.wpm }.max() ?? 1
            let minWpm = max(0, (results.map { $0.wpm }.min() ?? 0) - 10)
            let range = maxWpm - minWpm
            let w = geo.size.width
            let h = geo.size.height
            let step = w / CGFloat(results.count - 1)

            return AnyView(
                ZStack(alignment: .topLeading) {
                    Path { path in
                        for (i, r) in results.enumerated() {
                            let x = CGFloat(i) * step
                            let y = h - CGFloat((r.wpm - minWpm) / max(range, 1)) * h
                            if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                            else { path.addLine(to: CGPoint(x: x, y: y)) }
                        }
                    }
                    .stroke(TypoTheme.accent, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

                    // Dots
                    ForEach(Array(results.enumerated()), id: \.offset) { i, r in
                        let x = CGFloat(i) * step
                        let y = h - CGFloat((r.wpm - minWpm) / max(range, 1)) * h
                        Circle()
                            .fill(TypoTheme.accent)
                            .frame(width: 5, height: 5)
                            .position(x: x, y: y)
                    }
                }
            )
        }
    }
}

struct ResultRow: View {
    let result: TypoResult

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text("\(Int(result.wpm)) WPM")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(TypoTheme.accent)
                    Text("\(Int(result.accuracy))% acc")
                        .font(.system(size: 13))
                        .foregroundStyle(TypoTheme.textSecondary)
                }
                Text("\(result.mode) · \(result.date.formatted(date: .abbreviated, time: .shortened))")
                    .font(.system(size: 12))
                    .foregroundStyle(TypoTheme.textSecondary)
            }
            Spacer()
            Text("\(Int(result.rawWpm)) raw")
                .font(.system(size: 12))
                .foregroundStyle(TypoTheme.textSecondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(TypoTheme.surface, in: RoundedRectangle(cornerRadius: 12))
    }
}
