import SwiftUI
import SwiftData

struct CyclesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Period.startDate, order: .reverse) private var periods: [Period]
    @AppStorage("luna.defaultCycle") private var defaultCycle = 28
    @AppStorage("luna.defaultPeriod") private var defaultPeriod = 5

    @State private var editing: Period?
    @State private var showingAdd = false

    private var predictor: CyclePredictor {
        CyclePredictor.make(periods: periods, defaultCycle: defaultCycle, defaultPeriod: defaultPeriod)
    }

    // Pair each period with the cycle length to the NEXT (more recent) period.
    private var rows: [(period: Period, cycleLen: Int?)] {
        let asc = periods.sorted { $0.startDate < $1.startDate }
        var map: [UUID: Int] = [:]
        for i in 1..<max(1, asc.count) {
            let d = Calendar.current.dateComponents([.day], from: asc[i-1].startDate, to: asc[i].startDate).day
            map[asc[i-1].id] = d
        }
        return periods.map { ($0, map[$0.id]) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if periods.isEmpty {
                    EmptyStateView(icon: "repeat", title: "No cycles logged",
                                   message: "Log your periods on the Today tab and they'll be summarised here.")
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            summary
                            ForEach(rows, id: \.period.id) { row in
                                Button { editing = row.period } label: { card(row.period, row.cycleLen) }
                                    .buttonStyle(.plain)
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("Cycles")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add a past period")
                }
            }
            .sheet(item: $editing) { PeriodEditView(period: $0) }
            .sheet(isPresented: $showingAdd) { PeriodEditView(period: nil) }
        }
    }

    private var summary: some View {
        GlassCard {
            HStack {
                StatTile(value: "\(predictor.averageCycle)", label: "Avg cycle", tint: LunaColors.luteal)
                Divider().frame(height: 38).overlay(Brand.hairline)
                StatTile(value: "\(predictor.averagePeriod)", label: "Avg period")
                Divider().frame(height: 38).overlay(Brand.hairline)
                StatTile(value: "\(periods.count)", label: "Logged")
            }
        }
    }

    private func card(_ p: Period, _ cycleLen: Int?) -> some View {
        GlassCard {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(LunaColors.period.opacity(0.16)).frame(width: 46, height: 46)
                    Image(systemName: "drop.fill").foregroundStyle(LunaColors.period)
                }
                .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text(Format.day.string(from: p.startDate))
                        .font(.headline).foregroundStyle(Brand.text)
                    Text(p.isOngoing ? "Ongoing · \(p.lengthDays) days so far"
                                     : "\(p.lengthDays) day period")
                        .font(.subheadline).foregroundStyle(Brand.text2)
                }
                Spacer()
                if let len = cycleLen {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("\(len)").font(Brand.mono(18, weight: .semibold)).foregroundStyle(Brand.text)
                        Text("day cycle").font(.caption2).foregroundStyle(Brand.text3)
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}
