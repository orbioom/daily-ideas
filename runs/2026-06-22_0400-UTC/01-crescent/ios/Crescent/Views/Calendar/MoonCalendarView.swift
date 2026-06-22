import SwiftUI

struct MoonCalendarView: View {
    @State private var displayMonth = Date()
    private let cal = Calendar.current

    var body: some View {
        NavigationStack {
            ZStack {
                CrescentTheme.navy.ignoresSafeArea()
                VStack(spacing: 0) {
                    monthHeader
                    weekdayRow
                    calendarGrid
                    Spacer()
                }
            }
            .navigationTitle("Moon Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: prevMonth) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(CrescentTheme.gold)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: nextMonth) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(CrescentTheme.gold)
                    }
                }
            }
        }
    }

    private var monthName: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMMM yyyy"
        return fmt.string(from: displayMonth)
    }

    private var monthHeader: some View {
        Text(monthName)
            .font(.system(size: 22, weight: .light, design: .serif))
            .foregroundColor(CrescentTheme.pearl)
            .padding()
    }

    private var weekdayRow: some View {
        HStack {
            ForEach(["Mon","Tue","Wed","Thu","Fri","Sat","Sun"], id: \.self) { d in
                Text(d)
                    .font(.caption2)
                    .foregroundColor(CrescentTheme.silver)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 8)
    }

    private var calendarGrid: some View {
        let phases = MoonEngine.calendarPhases(for: displayMonth)
        let firstDay = cal.date(from: cal.dateComponents([.year, .month], from: displayMonth)) ?? displayMonth
        let weekdayOffset = (cal.component(.weekday, from: firstDay) + 5) % 7

        return LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 7), spacing: 8) {
            ForEach(0..<weekdayOffset, id: \.self) { _ in Color.clear.frame(height: 50) }
            ForEach(phases, id: \.date) { item in
                CalendarCell(date: item.date, phase: item.phase)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
    }

    private func prevMonth() {
        displayMonth = cal.date(byAdding: .month, value: -1, to: displayMonth) ?? displayMonth
    }
    private func nextMonth() {
        displayMonth = cal.date(byAdding: .month, value:  1, to: displayMonth) ?? displayMonth
    }
}

private struct CalendarCell: View {
    let date: Date
    let phase: MoonPhase
    private let cal = Calendar.current
    private var isToday: Bool { cal.isDateInToday(date) }

    var body: some View {
        VStack(spacing: 2) {
            Text("\(cal.component(.day, from: date))")
                .font(.caption2)
                .foregroundColor(isToday ? CrescentTheme.gold : CrescentTheme.silver)
            Text(phase.symbol)
                .font(.caption)
        }
        .frame(height: 48)
        .frame(maxWidth: .infinity)
        .background(isToday ? CrescentTheme.cardBg : Color.clear)
        .cornerRadius(8)
    }
}
