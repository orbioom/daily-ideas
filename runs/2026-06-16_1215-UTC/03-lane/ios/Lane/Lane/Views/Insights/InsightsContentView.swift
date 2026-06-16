import SwiftUI
import SwiftData
import Charts

struct InsightsContentView: View {
    let boards: [Board]
    @State private var selectedBoardID: UUID?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var weekly: [(weekStart: Date, count: Int)] {
        BoardEngine.completedPerWeek(in: boards, weeks: 6)
    }
    private var overdue: Int { BoardEngine.overdueCount(in: boards) }
    private var dueSoon: Int { BoardEngine.dueSoonCount(in: boards) }
    private var busiest: Board? { BoardEngine.busiestBoard(in: boards) }

    private var selectedBoard: Board? {
        if let id = selectedBoardID, let match = boards.first(where: { $0.id == id }) {
            return match
        }
        return boards.first
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                tiles
                throughputCard
                columnBreakdownCard
                busiestCard
            }
            .padding(16)
        }
    }

    // MARK: - Tiles

    private var tiles: some View {
        HStack(spacing: 12) {
            StatTile(value: "\(overdue)", label: "Overdue", symbol: "exclamationmark.triangle.fill", color: Theme.bad)
            StatTile(value: "\(dueSoon)", label: "Due soon", symbol: "clock.fill", color: Theme.warn)
            StatTile(value: "\(totalCompleted)", label: "Done", symbol: "checkmark.seal.fill", color: Theme.good)
        }
    }

    private var totalCompleted: Int {
        boards.reduce(0) { $0 + BoardEngine.completedCount(for: $1) }
    }

    // MARK: - Throughput

    private var throughputCard: some View {
        InsightCard(title: "Completed per week", subtitle: "Last 6 weeks") {
            if weekly.allSatisfy({ $0.count == 0 }) {
                emptyChart("No completed cards yet")
            } else {
                Chart(weekly, id: \.weekStart) { item in
                    BarMark(
                        x: .value("Week", item.weekStart, unit: .weekOfYear),
                        y: .value("Completed", item.count)
                    )
                    .foregroundStyle(Theme.accent)
                    .cornerRadius(5)
                    .accessibilityLabel(DateUtils.shortDate(item.weekStart))
                    .accessibilityValue("\(item.count) completed")
                }
                .chartXAxis {
                    AxisMarks(values: weekly.map { $0.weekStart }) { value in
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(DateUtils.shortDate(date))
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .frame(height: 180)
                .animation(reduceMotion ? nil : .easeInOut, value: weekly.map { $0.count })
            }
        }
    }

    // MARK: - Column breakdown

    private var columnBreakdownCard: some View {
        InsightCard(title: "Cards by lane", subtitle: selectedBoard?.name ?? "—") {
            VStack(spacing: 12) {
                if boards.count > 1 {
                    Picker("Board", selection: boardPickerBinding) {
                        ForEach(boards) { board in
                            Text(board.name).tag(board.id)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Theme.accent)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let board = selectedBoard {
                    let counts = BoardEngine.cardCounts(for: board)
                    if counts.allSatisfy({ $0.count == 0 }) {
                        emptyChart("This board has no cards")
                    } else {
                        Chart(counts, id: \.column.id) { item in
                            BarMark(
                                x: .value("Cards", item.count),
                                y: .value("Lane", item.column.name)
                            )
                            .foregroundStyle(Color(hex: UInt(max(0, item.column.colorHex))))
                            .cornerRadius(5)
                            .annotation(position: .trailing) {
                                Text("\(item.count)")
                                    .font(.caption2)
                                    .foregroundStyle(Theme.inkSoft)
                            }
                            .accessibilityLabel(item.column.name)
                            .accessibilityValue("\(item.count) cards")
                        }
                        .frame(height: max(120, CGFloat(counts.count) * 38))
                    }
                } else {
                    emptyChart("No board selected")
                }
            }
        }
    }

    private var boardPickerBinding: Binding<UUID> {
        Binding(
            get: { selectedBoard?.id ?? (boards.first?.id ?? UUID()) },
            set: { selectedBoardID = $0 }
        )
    }

    // MARK: - Busiest

    private var busiestCard: some View {
        InsightCard(title: "Busiest board", subtitle: "Most active cards") {
            if let busiest {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(hex: UInt(max(0, busiest.colorHex))).opacity(0.18))
                            .frame(width: 52, height: 52)
                        Image(systemName: busiest.symbolName)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(Color(hex: UInt(max(0, busiest.colorHex))))
                            .accessibilityHidden(true)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(busiest.name)
                            .font(Theme.rounded(17, .bold))
                            .foregroundStyle(Theme.ink)
                        Text("\(BoardEngine.activeCardCount(busiest)) active cards")
                            .font(.subheadline)
                            .foregroundStyle(Theme.inkSoft)
                    }
                    Spacer()
                    ProgressRing(progress: BoardEngine.progress(for: busiest), size: 46, lineWidth: 5,
                                 tint: Color(hex: UInt(max(0, busiest.colorHex))))
                }
                .accessibilityElement(children: .combine)
            } else {
                emptyChart("No active boards")
            }
        }
    }

    private func emptyChart(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(Theme.inkSoft)
            .frame(maxWidth: .infinity, minHeight: 80)
    }
}

// MARK: - Reusable cards

struct StatTile: View {
    let value: String
    let label: String
    let symbol: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(color)
                .accessibilityHidden(true)
            Text(value)
                .font(Theme.rounded(24, .bold))
                .foregroundStyle(Theme.ink)
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.inkSoft)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .stroke(Theme.hairline, lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(value) \(label)")
    }
}

struct InsightCard<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.rounded(17, .bold))
                    .foregroundStyle(Theme.ink)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Theme.inkSoft)
            }
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .stroke(Theme.hairline, lineWidth: 1)
        )
    }
}
