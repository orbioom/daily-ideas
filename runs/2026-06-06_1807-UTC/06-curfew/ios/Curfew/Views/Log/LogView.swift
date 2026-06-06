import SwiftUI
import SwiftData
import Charts

struct LogView: View {
    @Query(sort: \Intake.time, order: .reverse) private var intakes: [Intake]
    @AppStorage("dailyLimitMg") private var dailyLimit = 400.0
    @State private var editing: Intake?

    private var byDay: [(day: Date, items: [Intake], total: Double)] {
        let groups = Dictionary(grouping: intakes) { Calendar.current.startOfDay(for: $0.time) }
        return groups.map { (day: $0.key, items: $0.value.sorted { $0.time > $1.time },
                             total: $0.value.reduce(0) { $0 + $1.mg }) }
            .sorted { $0.day > $1.day }
    }
    private var dailyTotals: [(day: Date, total: Double)] {
        byDay.prefix(14).map { (day: $0.day, total: $0.total) }.sorted { $0.day < $1.day }
    }
    private var avgDaily: Double {
        guard !byDay.isEmpty else { return 0 }
        return byDay.reduce(0) { $0 + $1.total } / Double(byDay.count)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if intakes.isEmpty {
                    EmptyStateView(icon: "list.bullet", title: "No history yet",
                                   message: "Your logged drinks will gather here, grouped by day with daily totals.")
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            HStack(spacing: 12) {
                                StatTile(value: Fmt.mg(avgDaily), label: "Avg / day")
                                StatTile(value: "\(byDay.count)", label: "Days logged")
                            }
                            if dailyTotals.count >= 2 {
                                VStack(alignment: .leading, spacing: 12) {
                                    Eyebrow(text: "Daily total (mg)")
                                    Chart(dailyTotals, id: \.day) { item in
                                        BarMark(x: .value("Day", item.day, unit: .day),
                                                y: .value("mg", item.total))
                                        .foregroundStyle(item.total > dailyLimit ? Brand.danger.gradient : Brand.info.gradient)
                                        .cornerRadius(3)
                                        RuleMark(y: .value("Limit", dailyLimit))
                                            .foregroundStyle(Brand.warn.opacity(0.5))
                                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                                    }
                                    .frame(height: 150)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading).glassCard(padding: 18)
                            }
                            ForEach(byDay, id: \.day) { group in
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text(group.day, format: .dateTime.weekday().month().day())
                                            .font(.subheadline.weight(.semibold)).foregroundStyle(Brand.text)
                                        Spacer()
                                        Text(Fmt.mg(group.total))
                                            .font(Brand.mono(13, weight: .semibold))
                                            .foregroundStyle(group.total > dailyLimit ? Brand.danger : Brand.text2)
                                    }
                                    .padding(.horizontal, 4)
                                    ForEach(group.items) { i in
                                        Button { editing = i } label: { row(i) }.buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Log")
            .sheet(item: $editing) { IntakeEditView(intake: $0) }
        }
    }

    private func row(_ i: Intake) -> some View {
        HStack(spacing: 12) {
            Image(systemName: i.category.icon).foregroundStyle(Brand.text2).frame(width: 24)
                .accessibilityHidden(true)
            Text(i.name).font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
            Spacer()
            Text(Fmt.time(i.time)).font(Brand.mono(12)).foregroundStyle(Brand.text3)
            Text(Fmt.mg(i.mg)).font(Brand.mono(13, weight: .semibold)).foregroundStyle(Brand.text)
        }
        .glassCard(padding: 12)
    }
}
