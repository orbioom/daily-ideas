import SwiftUI
import SwiftData

struct CalendarView: View {
    @AppStorage("buffer") private var buffer = 100.0
    @AppStorage("currencyCode") private var currencyCode = "USD"
    @Query private var recurring: [RecurringItem]
    @Query private var oneOffs: [OneOffItem]

    private var forecast: Forecast {
        ForecastContext.current(recurring: recurring, oneOffs: oneOffs)
    }
    private var eventfulDays: [DayProjection] {
        forecast.projections.filter { !$0.events.isEmpty }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if eventfulDays.isEmpty {
                    EmptyState(icon: "calendar",
                               title: "Nothing scheduled",
                               message: "Add your income and bills in the Money tab and they'll appear here as a day-by-day forecast.")
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10, pinnedViews: [.sectionHeaders]) {
                            ForEach(groupedByMonth, id: \.0) { month, days in
                                Section {
                                    ForEach(days) { day in
                                        NavigationLink(value: day.date) {
                                            DayRow(day: day, buffer: buffer, currency: currencyCode)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                } header: {
                                    HStack {
                                        Text(month).font(.system(size: 13, weight: .bold)).tracking(0.5)
                                            .foregroundStyle(Theme.inkFaint)
                                        Spacer()
                                    }
                                    .padding(.vertical, 6).padding(.horizontal, 4)
                                    .background(Theme.bg)
                                }
                            }
                        }
                        .padding(.horizontal, 16).padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Calendar")
            .navigationDestination(for: Date.self) { date in
                if let day = forecast.projections.first(where: { $0.date == date }) {
                    DayDetailView(day: day, buffer: buffer, currency: currencyCode)
                }
            }
        }
    }

    private var groupedByMonth: [(String, [DayProjection])] {
        let cal = Calendar.current
        let groups = Dictionary(grouping: eventfulDays) { day -> Date in
            cal.date(from: cal.dateComponents([.year, .month], from: day.date)) ?? day.date
        }
        return groups.keys.sorted().map { key in
            (key.formatted(.dateTime.month(.wide).year()), groups[key]!.sorted { $0.date < $1.date })
        }
    }
}

struct DayRow: View {
    let day: DayProjection
    let buffer: Double
    let currency: String

    var body: some View {
        HStack(spacing: 14) {
            VStack(spacing: 0) {
                Text(day.date, format: .dateTime.day()).font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                Text(day.date, format: .dateTime.weekday(.abbreviated)).font(.system(size: 11))
                    .foregroundStyle(Theme.inkFaint)
            }
            .frame(width: 42)
            VStack(alignment: .leading, spacing: 3) {
                ForEach(day.events.prefix(2)) { e in
                    HStack(spacing: 6) {
                        Circle().fill(e.kind == .income ? Theme.accent : Theme.inkFaint).frame(width: 6, height: 6)
                        Text(e.name).font(.system(size: 14)).foregroundStyle(Theme.ink).lineLimit(1)
                        Spacer()
                        Text(Money.string(e.signedAmount, code: currency, showSign: true))
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(e.kind == .income ? Theme.accent : Theme.inkSoft)
                    }
                }
                if day.events.count > 2 {
                    Text("+\(day.events.count - 2) more").font(.system(size: 12)).foregroundStyle(Theme.inkFaint)
                }
            }
            VStack(alignment: .trailing, spacing: 2) {
                Circle().fill(Theme.status(forBalance: day.endBalance, buffer: buffer))
                    .frame(width: 8, height: 8)
                Text(Money.whole(day.endBalance, code: currency))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.status(forBalance: day.endBalance, buffer: buffer))
            }
            .frame(width: 64)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.surface))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(day.date.formatted(.dateTime.month().day())), projected balance \(Money.string(day.endBalance, code: currency))")
    }
}

struct DayDetailView: View {
    let day: DayProjection
    let buffer: Double
    let currency: String

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Card {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Projected end-of-day balance").font(.system(size: 13)).foregroundStyle(Theme.inkSoft)
                        Text(Money.string(day.endBalance, code: currency))
                            .font(Theme.num(38))
                            .foregroundStyle(Theme.status(forBalance: day.endBalance, buffer: buffer))
                        HStack(spacing: 16) {
                            Label(Money.string(day.startBalance, code: currency), systemImage: "sunrise")
                            Label(Money.string(day.net, code: currency, showSign: true), systemImage: "arrow.left.arrow.right")
                        }
                        .font(.system(size: 13)).foregroundStyle(Theme.inkSoft).labelStyle(.titleAndIcon)
                    }
                }
                VStack(alignment: .leading, spacing: 10) {
                    SectionLabel(text: "Money moving")
                    ForEach(day.events) { e in
                        HStack(spacing: 12) {
                            CategoryBadge(category: e.category, kind: e.kind)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(e.name).font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.ink)
                                Text("\(e.category) · \(e.isRecurring ? "Recurring" : "One-time")")
                                    .font(.system(size: 12)).foregroundStyle(Theme.inkFaint)
                            }
                            Spacer()
                            Text(Money.string(e.signedAmount, code: currency, showSign: true))
                                .font(Theme.num(17))
                                .foregroundStyle(e.kind == .income ? Theme.accent : Theme.ink)
                        }
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.surface))
                    }
                }
            }
            .padding(16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle(day.date.formatted(.dateTime.weekday(.wide).month().day()))
        .navigationBarTitleDisplayMode(.inline)
    }
}
