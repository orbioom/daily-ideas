import SwiftUI
import SwiftData

struct CalendarView: View {
    @Query(sort: \Period.startDate, order: .reverse) private var periods: [Period]
    @Query private var logs: [DayLog]
    @AppStorage("luna.defaultCycle") private var defaultCycle = 28
    @AppStorage("luna.defaultPeriod") private var defaultPeriod = 5
    @AppStorage("luna.showFertility") private var showFertility = true

    @State private var month = Calendar.current.startOfDay(for: .now)
    @State private var logDate: Date?

    private let cal = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    private var predictor: CyclePredictor {
        CyclePredictor.make(periods: periods, defaultCycle: defaultCycle, defaultPeriod: defaultPeriod)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    VStack(spacing: 18) {
                        header
                        weekdays
                        grid
                        legend
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Calendar")
            .sheet(item: Binding(get: { logDate.map { IdentifiableDate(date: $0) } },
                                 set: { logDate = $0?.date })) { wrapped in
                DayLogSheet(date: wrapped.date)
            }
        }
    }

    private var header: some View {
        HStack {
            Button { shift(-1) } label: { Image(systemName: "chevron.left") }
                .accessibilityLabel("Previous month")
            Spacer()
            Text(Format.monthYear.string(from: month)).font(.title3.weight(.semibold)).foregroundStyle(Brand.text)
            Spacer()
            Button { shift(1) } label: { Image(systemName: "chevron.right") }
                .accessibilityLabel("Next month")
        }
        .foregroundStyle(Brand.text)
    }

    private var weekdays: some View {
        HStack {
            ForEach(symbols, id: \.self) { s in
                Text(s).font(.caption2).foregroundStyle(Brand.text3).frame(maxWidth: .infinity)
            }
        }
    }

    private var grid: some View {
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                if let day { cell(day) } else { Color.clear.frame(height: 46) }
            }
        }
    }

    private func cell(_ day: Date) -> some View {
        let kind = predictor.kind(for: day, periods: periods)
        let log = logs.first { cal.isDate($0.date, inSameDayAs: day) }
        let isToday = cal.isDateInToday(day)
        let (fill, stroke) = style(for: kind)
        return Button {
            logDate = day; Haptics.selection()
        } label: {
            VStack(spacing: 3) {
                ZStack {
                    Circle().fill(fill)
                        .overlay(Circle().strokeBorder(stroke, style: StrokeStyle(lineWidth: 1.5, dash: kind == .predictedPeriod ? [3,2] : [])))
                        .overlay(isToday ? Circle().strokeBorder(Brand.text, lineWidth: 2) : nil)
                        .frame(width: 36, height: 36)
                    Text("\(cal.component(.day, from: day))")
                        .font(Brand.mono(13))
                        .foregroundStyle(kind == .period ? .white : Brand.text)
                }
                if let log, log.flow != .none {
                    Circle().fill(log.flow.color).frame(width: 5, height: 5)
                } else {
                    Color.clear.frame(width: 5, height: 5)
                }
            }
            .frame(height: 46)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(cal.component(.day, from: day)). \(accLabel(kind))")
    }

    private func style(for kind: CyclePredictor.DayKind) -> (Color, Color) {
        switch kind {
        case .period: return (LunaColors.period, .clear)
        case .predictedPeriod: return (LunaColors.predicted.opacity(0.25), LunaColors.period.opacity(0.7))
        case .fertile: return (showFertility ? LunaColors.fertile.opacity(0.22) : .clear, .clear)
        case .ovulation: return (showFertility ? LunaColors.ovulation.opacity(0.3) : .clear, showFertility ? LunaColors.ovulation : .clear)
        case .none: return (.clear, .clear)
        }
    }

    private func accLabel(_ kind: CyclePredictor.DayKind) -> String {
        switch kind {
        case .period: return "Period day"
        case .predictedPeriod: return "Predicted period"
        case .fertile: return "Fertile window"
        case .ovulation: return "Ovulation"
        case .none: return "No prediction"
        }
    }

    private var legend: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                legendRow(LunaColors.period, "Period (logged)")
                legendRow(LunaColors.predicted, "Predicted period")
                if showFertility {
                    legendRow(LunaColors.fertile, "Fertile window")
                    legendRow(LunaColors.ovulation, "Ovulation (est.)")
                }
            }
        }
    }

    private func legendRow(_ c: Color, _ t: String) -> some View {
        HStack(spacing: 8) {
            Circle().fill(c).frame(width: 14, height: 14)
            Text(t).font(.subheadline).foregroundStyle(Brand.text2)
        }
        .accessibilityElement(children: .combine)
    }

    // helpers
    private var symbols: [String] {
        let s = cal.shortStandaloneWeekdaySymbols
        let f = cal.firstWeekday - 1
        return Array(s[f...] + s[..<f])
    }
    private var days: [Date?] {
        guard let interval = cal.dateInterval(of: .month, for: month) else { return [] }
        let first = interval.start
        let weekday = cal.component(.weekday, from: first)
        let leading = (weekday - cal.firstWeekday + 7) % 7
        let count = cal.range(of: .day, in: .month, for: month)?.count ?? 30
        var cells: [Date?] = Array(repeating: nil, count: leading)
        for d in 0..<count { cells.append(cal.date(byAdding: .day, value: d, to: first)) }
        while cells.count % 7 != 0 { cells.append(nil) }
        return cells
    }
    private func shift(_ by: Int) {
        if let m = cal.date(byAdding: .month, value: by, to: month) { month = m }
    }
}

struct IdentifiableDate: Identifiable {
    let date: Date
    var id: TimeInterval { date.timeIntervalSince1970 }
}
