import SwiftUI
import SwiftData

struct CalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Query(sort: \DayLog.date, order: .reverse) private var allLogs: [DayLog]

    @State private var monthAnchor: Date = Calendar.current.startOfDay(for: Date())
    @State private var selectedDate: Date?
    @State private var paywallReason: PaywallReason?

    private let cal = Calendar.current

    /// Map start-of-day → log for fast lookup.
    private var logsByDay: [Date: DayLog] {
        var dict: [Date: DayLog] = [:]
        for log in allLogs { dict[cal.startOfDay(for: log.date)] = log }
        return dict
    }

    private var maxFlashes: Int {
        max(1, allLogs.map(\.hotFlashCount).max() ?? 1)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    monthHeader
                    weekdayRow
                    grid
                    legend
                    if allLogs.isEmpty {
                        EmptyStateView(symbol: "calendar.badge.plus",
                                       title: "Nothing logged yet",
                                       message: "Your tracked days will bloom here as a warm heat-map. Start with today's check-in.")
                            .padding(.top, 8)
                    }
                }
                .padding(16)
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(item: $selectedDate) { date in
                DayDetailView(date: date)
            }
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
        }
    }

    // MARK: - Month header

    private var monthHeader: some View {
        HStack {
            Button { shiftMonth(-1) } label: {
                Image(systemName: "chevron.left").font(.system(size: 16, weight: .semibold))
            }
            .accessibilityLabel("Previous month")
            Spacer()
            Text(monthTitle)
                .font(Theme.serif(20, .semibold))
                .foregroundStyle(Theme.ink)
            Spacer()
            Button { shiftMonth(1) } label: {
                Image(systemName: "chevron.right").font(.system(size: 16, weight: .semibold))
            }
            .disabled(isCurrentMonth)
            .opacity(isCurrentMonth ? 0.35 : 1)
            .accessibilityLabel("Next month")
        }
        .foregroundStyle(Theme.accent)
        .padding(.horizontal, 4)
    }

    private var monthTitle: String {
        monthAnchor.formatted(.dateTime.month(.wide).year())
    }

    private var isCurrentMonth: Bool {
        cal.isDate(monthAnchor, equalTo: Date(), toGranularity: .month)
    }

    private var weekdayRow: some View {
        HStack(spacing: 6) {
            ForEach(weekdaySymbols, id: \.self) { sym in
                Text(sym)
                    .font(Theme.rounded(12, .semibold))
                    .foregroundStyle(Theme.inkFaint)
                    .frame(maxWidth: .infinity)
            }
        }
        .accessibilityHidden(true)
    }

    private var weekdaySymbols: [String] {
        let fmt = cal.veryShortWeekdaySymbols
        // Rotate so the first symbol matches the calendar's firstWeekday.
        let first = cal.firstWeekday - 1
        guard first >= 0, first < fmt.count else { return fmt }
        return Array(fmt[first...] + fmt[..<first])
    }

    // MARK: - Grid

    private var grid: some View {
        let days = monthDays()
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
            ForEach(days) { cell in
                if let date = cell.date {
                    dayCell(date)
                } else {
                    Color.clear.frame(height: 46)
                }
            }
        }
    }

    private func dayCell(_ date: Date) -> some View {
        let day = cal.startOfDay(for: date)
        let log = logsByDay[day]
        let isToday = cal.isDateInToday(day)
        let isFuture = day > cal.startOfDay(for: Date())
        let inFreeWindow = withinFreeWindow(day)

        return Button {
            handleTap(day: day, isFuture: isFuture, inFreeWindow: inFreeWindow)
        } label: {
            VStack(spacing: 3) {
                Text("\(cal.component(.day, from: day))")
                    .font(Theme.rounded(14, isToday ? .bold : .regular))
                    .foregroundStyle(isFuture ? Theme.inkFaint : Theme.ink)
                ZStack {
                    Circle()
                        .fill(cellColor(log: log, inFreeWindow: inFreeWindow))
                        .frame(width: 14, height: 14)
                    if let log, log.flow.isBleeding, settings.trackCycle {
                        Circle()
                            .strokeBorder(Theme.bad, lineWidth: 2)
                            .frame(width: 18, height: 18)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isToday ? Theme.accentSoft : Color.clear)
            )
        }
        .buttonStyle(PressableScale())
        .disabled(isFuture)
        .opacity(isFuture ? 0.4 : 1)
        .accessibilityLabel(cellAccessibility(date: day, log: log, inFreeWindow: inFreeWindow))
    }

    private func cellColor(log: DayLog?, inFreeWindow: Bool) -> Color {
        guard inFreeWindow else { return Theme.hairline }
        guard let log, log.hotFlashCount > 0 else { return Theme.surfaceAlt }
        let intensity = Double(log.hotFlashCount) / Double(maxFlashes)
        return Theme.heatColor(intensity)
    }

    private func cellAccessibility(date: Date, log: DayLog?, inFreeWindow: Bool) -> String {
        let dayStr = date.formatted(date: .abbreviated, time: .omitted)
        if !inFreeWindow { return "\(dayStr), locked — Pro unlocks full history" }
        guard let log else { return "\(dayStr), not logged" }
        var parts = ["\(dayStr)", "\(log.hotFlashCount) hot flashes"]
        if log.flow.isBleeding { parts.append("period") }
        return parts.joined(separator: ", ")
    }

    // MARK: - Legend

    private var legend: some View {
        HStack(spacing: 14) {
            legendItem(color: Theme.surfaceAlt, label: "None")
            legendItem(color: Theme.heatColor(0.4), label: "Some")
            legendItem(color: Theme.heatColor(1.0), label: "Many")
            if settings.trackCycle {
                HStack(spacing: 5) {
                    Circle().strokeBorder(Theme.bad, lineWidth: 2).frame(width: 14, height: 14)
                    Text("Period").font(Theme.rounded(11)).foregroundStyle(Theme.inkSoft)
                }
            }
            Spacer()
        }
        .accessibilityHidden(true)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 12, height: 12)
            Text(label).font(Theme.rounded(11)).foregroundStyle(Theme.inkSoft)
        }
    }

    // MARK: - Cells / month math

    private struct DayCell: Identifiable {
        let id: Int
        let date: Date?
    }

    private func monthDays() -> [DayCell] {
        guard let monthInterval = cal.dateInterval(of: .month, for: monthAnchor) else { return [] }
        let firstOfMonth = monthInterval.start
        let weekdayOfFirst = cal.component(.weekday, from: firstOfMonth)
        // Leading blanks based on firstWeekday.
        var leading = weekdayOfFirst - cal.firstWeekday
        if leading < 0 { leading += 7 }

        let daysInMonth = cal.range(of: .day, in: .month, for: monthAnchor)?.count ?? 30
        var cells: [DayCell] = []
        var idx = 0
        for _ in 0..<leading {
            cells.append(DayCell(id: idx, date: nil)); idx += 1
        }
        for dayNum in 1...daysInMonth {
            if let date = cal.date(byAdding: .day, value: dayNum - 1, to: firstOfMonth) {
                cells.append(DayCell(id: idx, date: date)); idx += 1
            }
        }
        return cells
    }

    private func withinFreeWindow(_ day: Date) -> Bool {
        if isPro { return true }
        let today = cal.startOfDay(for: Date())
        let diff = cal.dateComponents([.day], from: day, to: today).day ?? Int.max
        return diff >= 0 && diff <= Pro.freeHistoryDays
    }

    private func handleTap(day: Date, isFuture: Bool, inFreeWindow: Bool) {
        guard !isFuture else { return }
        if !inFreeWindow {
            paywallReason = .history
            return
        }
        Haptics.tap(enabled: settings.hapticsEnabled)
        selectedDate = day
    }

    private func shiftMonth(_ delta: Int) {
        guard let next = cal.date(byAdding: .month, value: delta, to: monthAnchor) else { return }
        if delta > 0 && next > Date() && !cal.isDate(next, equalTo: Date(), toGranularity: .month) {
            return
        }
        Haptics.selection(enabled: settings.hapticsEnabled)
        monthAnchor = next
    }
}
