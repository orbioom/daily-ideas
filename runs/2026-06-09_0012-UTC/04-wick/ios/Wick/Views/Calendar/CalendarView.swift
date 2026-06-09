import SwiftUI
import SwiftData

struct CalendarView: View {
    @Query private var trades: [Trade]
    @AppStorage("wick.symbol") private var symbol = "$"
    @State private var month = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: .now)) ?? .now
    @State private var selectedDay: Date?

    private let cal = Calendar.current

    private var dailyPL: [Date: Double] { TradeStats.dailyPL(trades, month: month, calendar: cal) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    monthHeader
                    if trades.filter({ !$0.isOpen }).isEmpty {
                        EmptyStateView(icon: "calendar",
                                       title: "No closed trades",
                                       message: "Close some trades to see your daily P/L calendar.")
                            .glassCard()
                    } else {
                        calendarCard
                        monthStats
                        if let day = selectedDay { dayTrades(day) }
                    }
                }
                .padding(20)
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle("Calendar")
        }
    }

    private var monthHeader: some View {
        HStack {
            Button { shift(-1) } label: { Image(systemName: "chevron.left") }
                .accessibilityLabel("Previous month")
            Spacer()
            Text(Format.monthYear.string(from: month)).font(.headline).foregroundStyle(Brand.text)
            Spacer()
            Button { shift(1) } label: { Image(systemName: "chevron.right") }
                .accessibilityLabel("Next month")
                .disabled(isCurrentMonth)
        }
        .padding(.horizontal, 4)
    }

    private var isCurrentMonth: Bool {
        cal.isDate(month, equalTo: .now, toGranularity: .month)
    }

    private func shift(_ by: Int) {
        Haptics.selection()
        if let m = cal.date(byAdding: .month, value: by, to: month) {
            month = m; selectedDay = nil
        }
    }

    private var calendarCard: some View {
        GlassCard {
            VStack(spacing: 8) {
                HStack {
                    ForEach(weekdaySymbols, id: \.self) { d in
                        Text(d).font(.caption2).foregroundStyle(Brand.text3).frame(maxWidth: .infinity)
                    }
                }
                let cols = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
                LazyVGrid(columns: cols, spacing: 4) {
                    ForEach(Array(daysGrid.enumerated()), id: \.offset) { _, day in
                        dayCell(day)
                    }
                }
            }
        }
    }

    private func dayCell(_ day: Date?) -> some View {
        Group {
            if let day {
                let pl = dailyPL[cal.startOfDay(for: day)]
                let isSel = selectedDay.map { cal.isDate($0, inSameDayAs: day) } ?? false
                Button {
                    Haptics.selection()
                    selectedDay = (pl != nil) ? day : nil
                } label: {
                    VStack(spacing: 1) {
                        Text("\(cal.component(.day, from: day))")
                            .font(Brand.mono(11)).foregroundStyle(Brand.text2)
                        if let pl {
                            Text(Money.compact(pl, symbol: ""))
                                .font(Brand.mono(9, weight: .semibold))
                                .foregroundStyle(pl >= 0 ? Brand.live : Brand.danger)
                                .lineLimit(1).minimumScaleFactor(0.6)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 42)
                    .background(cellColor(pl), in: RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(isSel ? Brand.text : .clear, lineWidth: 1.5))
                }
                .buttonStyle(.plain)
                .disabled(pl == nil)
                .accessibilityLabel(accessibilityText(day, pl))
            } else {
                Color.clear.frame(maxWidth: .infinity, minHeight: 42)
            }
        }
    }

    private func cellColor(_ pl: Double?) -> Color {
        guard let pl, pl != 0 else { return Brand.hairline.opacity(0.3) }
        let base = pl >= 0 ? Brand.live : Brand.danger
        let mag = min(abs(pl) / max(1, maxAbsPL), 1)
        return base.opacity(0.18 + mag * 0.4)
    }

    private var maxAbsPL: Double { dailyPL.values.map(abs).max() ?? 1 }

    private func accessibilityText(_ day: Date, _ pl: Double?) -> String {
        let d = Format.shortDate.string(from: day)
        guard let pl else { return "\(d), no trades" }
        return "\(d), \(Money.string(pl, symbol: symbol, showsSign: true))"
    }

    private var monthStats: some View {
        let values = dailyPL.values
        let total = values.reduce(0, +)
        let green = values.filter { $0 > 0 }.count
        let red = values.filter { $0 < 0 }.count
        return GlassCard {
            HStack {
                stat("Month P/L", Money.string(total, symbol: symbol, showsSign: true),
                     total >= 0 ? Brand.live : Brand.danger)
                Spacer()
                stat("Green days", "\(green)", Brand.live)
                Spacer()
                stat("Red days", "\(red)", Brand.danger)
            }
        }
    }

    private func stat(_ label: String, _ value: String, _ tint: Color) -> some View {
        VStack(spacing: 2) {
            Text(value).font(Brand.mono(15, weight: .semibold)).foregroundStyle(tint)
            Text(label).font(.caption2).foregroundStyle(Brand.text3)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    private func dayTrades(_ day: Date) -> some View {
        let dayTrades = trades.filter { t in
            guard let exit = t.exitDate else { return false }
            return cal.isDate(exit, inSameDayAs: day)
        }
        return GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Eyebrow(text: Format.shortDate.string(from: day))
                ForEach(dayTrades) { t in
                    HStack {
                        Text(t.symbol).font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                        Text(t.direction.title).font(.caption).foregroundStyle(t.direction.tint)
                        Spacer()
                        if let pl = t.netPL {
                            Text(Money.string(pl, symbol: symbol, showsSign: true))
                                .font(Brand.mono(13)).foregroundStyle(pl >= 0 ? Brand.live : Brand.danger)
                        }
                    }
                    .padding(.vertical, 2)
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    // MARK: - Grid helpers

    private var weekdaySymbols: [String] {
        let s = cal.shortWeekdaySymbols
        let first = cal.firstWeekday - 1
        return Array(s[first...] + s[..<first]).map { String($0.prefix(2)) }
    }

    /// Days of the month padded with leading nils to align to the first weekday.
    private var daysGrid: [Date?] {
        guard let range = cal.range(of: .day, in: .month, for: month),
              let firstOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: month))
        else { return [] }
        let weekdayOfFirst = cal.component(.weekday, from: firstOfMonth)
        let leading = (weekdayOfFirst - cal.firstWeekday + 7) % 7
        var cells: [Date?] = Array(repeating: nil, count: leading)
        for day in range {
            cells.append(cal.date(byAdding: .day, value: day - 1, to: firstOfMonth))
        }
        return cells
    }
}
