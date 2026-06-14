import SwiftUI
import SwiftData

/// A month grid that highlights days with events (dots colored per event). Tap a
/// day to see its events below. Pro-gated; free users see a calm upsell.
struct CalendarView: View {
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query private var events: [CountdownEvent]

    @State private var monthAnchor = Date()
    @State private var selectedDay: Date?
    @State private var paywall: PaywallReason?

    private var engine: CountdownEngine { settings.engine }

    var body: some View {
        NavigationStack {
            Group {
                if isPro {
                    calendarBody
                } else {
                    lockedBody
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Calendar")
            .navigationDestination(for: CountdownEvent.self) { EventDetailView(event: $0) }
            .sheet(item: $paywall) { reason in PaywallView(reason: reason) }
        }
    }

    // MARK: Pro calendar

    private var calendarBody: some View {
        ScrollView {
            VStack(spacing: 16) {
                monthHeader
                weekdayRow
                grid
                daySection
            }
            .padding(16)
        }
    }

    private var monthHeader: some View {
        HStack {
            Button { step(-1) } label: {
                Image(systemName: "chevron.left").font(.system(size: 16, weight: .semibold))
            }
            .accessibilityLabel("Previous month")
            Spacer()
            Text(DateFmt.monthYear.string(from: monthAnchor))
                .font(Theme.rounded(20, .bold))
                .foregroundStyle(Theme.ink)
            Spacer()
            Button { step(1) } label: {
                Image(systemName: "chevron.right").font(.system(size: 16, weight: .semibold))
            }
            .accessibilityLabel("Next month")
        }
        .foregroundStyle(Theme.accent)
        .padding(.horizontal, 4)
        .overlay(alignment: .bottomTrailing) {
            if !engine.calendar.isDate(monthAnchor, equalTo: Date(), toGranularity: .month) {
                Button("Today") { withAnimation { monthAnchor = Date() } }
                    .font(Theme.rounded(12, .semibold))
                    .foregroundStyle(Theme.accent)
                    .offset(y: 26)
            }
        }
    }

    private var weekdayRow: some View {
        HStack(spacing: 0) {
            ForEach(Array(engine.orderedWeekdaySymbols().enumerated()), id: \.offset) { _, sym in
                Text(sym)
                    .font(Theme.rounded(12, .semibold))
                    .foregroundStyle(Theme.inkSoft)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 8)
        .accessibilityHidden(true)
    }

    private var grid: some View {
        let cells = engine.monthGrid(for: monthAnchor)
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
        return LazyVGrid(columns: columns, spacing: 6) {
            ForEach(Array(cells.enumerated()), id: \.offset) { _, day in
                if let day {
                    dayCell(day)
                } else {
                    Color.clear.frame(height: 46)
                }
            }
        }
    }

    private func dayCell(_ day: Date) -> some View {
        let dayEvents = engine.events(events, on: day)
        let isToday = engine.calendar.isDateInToday(day)
        let isSelected = selectedDay.map { engine.calendar.isDate($0, inSameDayAs: day) } ?? false
        let dayNum = engine.calendar.component(.day, from: day)

        return Button {
            Haptics.selection(enabled: settings.hapticsEnabled)
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.15)) {
                selectedDay = isSelected ? nil : day
            }
        } label: {
            VStack(spacing: 4) {
                Text("\(dayNum)")
                    .font(Theme.rounded(15, isToday ? .bold : .medium))
                    .foregroundStyle(isToday ? Theme.accent : Theme.ink)
                HStack(spacing: 3) {
                    ForEach(Array(dayEvents.prefix(3).enumerated()), id: \.offset) { _, e in
                        Circle().fill(e.theme.dot).frame(width: 5, height: 5)
                    }
                }
                .frame(height: 6)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? Theme.accentSoft : (isToday ? Theme.surfaceAlt : Color.clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(isSelected ? Theme.accent : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(dayAccessibility(day: day, count: dayEvents.count))
    }

    @ViewBuilder
    private var daySection: some View {
        if let day = selectedDay {
            let dayEvents = engine.sortedForHome(engine.events(events, on: day))
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: DateFmt.full.string(from: day),
                              count: dayEvents.isEmpty ? nil : dayEvents.count,
                              symbol: "calendar.day.timeline.left")
                if dayEvents.isEmpty {
                    Text("No events on this day.")
                        .font(Theme.rounded(15))
                        .foregroundStyle(Theme.inkSoft)
                        .padding(.vertical, 8)
                } else {
                    ForEach(dayEvents) { event in
                        NavigationLink(value: event) { dayRow(event) }
                            .buttonStyle(.plain)
                    }
                }
            }
            .padding(.top, 8)
        } else {
            VStack(spacing: 6) {
                Image(systemName: "hand.tap")
                    .font(.system(size: 22))
                    .foregroundStyle(Theme.inkFaint)
                Text("Tap a day to see its events")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
        }
    }

    private func dayRow(_ event: CountdownEvent) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(event.theme.gradient).frame(width: 38, height: 38)
                EventSymbolView(symbol: event.symbol, isEmoji: event.symbolIsEmoji,
                                size: 18, color: event.theme.onGradient)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title.isEmpty ? "Untitled" : event.title)
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.ink)
                Text(event.kind.title)
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkSoft)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.inkFaint)
        }
        .padding(12)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Theme.hairline, lineWidth: 1)
        )
    }

    // MARK: Locked state

    private var lockedBody: some View {
        VStack(spacing: 18) {
            Spacer()
            EmptyStateView(
                symbol: "calendar",
                title: "Calendar is a Pro feature",
                message: "See every event in a beautiful month grid with colored dots. Unlock with Cusp Pro.",
                actionTitle: "Unlock Cusp Pro",
                action: { paywall = .calendar }
            )
            Spacer()
            Spacer()
        }
    }

    // MARK: Helpers

    private func step(_ delta: Int) {
        Haptics.tap(enabled: settings.hapticsEnabled)
        if let d = engine.calendar.date(byAdding: .month, value: delta, to: monthAnchor) {
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
                monthAnchor = d
                selectedDay = nil
            }
        }
    }

    private func dayAccessibility(day: Date, count: Int) -> String {
        let base = DateFmt.full.string(from: day)
        if count == 0 { return base }
        return "\(base), \(count) event\(count == 1 ? "" : "s")"
    }
}
