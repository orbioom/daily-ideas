import SwiftUI
import SwiftData
import Charts

struct RunsView: View {
    @Query(sort: \Run.date, order: .reverse) private var runs: [Run]
    @AppStorage("distanceUnit") private var unitRaw = DistanceUnit.km.rawValue
    @AppStorage("weeklyGoalKm") private var weeklyGoalKm = 40.0
    @State private var showAdd = false
    @State private var kindFilter: RunKind? = nil

    private var goalMeters: Double { weeklyGoalKm * 1000 }
    private var goalFraction: Double { goalMeters > 0 ? min(1, weekMeters / goalMeters) : 0 }

    private var unit: DistanceUnit { DistanceUnit(rawValue: unitRaw) ?? .km }
    private var filtered: [Run] { runs.filter { kindFilter == nil || $0.kind == kindFilter } }

    /// Total distance over the last 7 days, in meters.
    private var weekMeters: Double {
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
        return runs.filter { $0.date >= cutoff }.reduce(0) { $0 + $1.distanceMeters }
    }
    /// Daily distances for the last 14 days for the mini chart.
    private var dailyTrend: [(date: Date, meters: Double)] {
        let cal = Calendar.current
        return (0..<14).reversed().map { offset -> (Date, Double) in
            let d = cal.date(byAdding: .day, value: -offset, to: cal.startOfDay(for: .now)) ?? .now
            let total = runs.filter { cal.isDate($0.date, inSameDayAs: d) }.reduce(0) { $0 + $1.distanceMeters }
            return (d, total)
        }.map { (date: $0.0, meters: $0.1) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if runs.isEmpty {
                    EmptyStateView(icon: "figure.run",
                                   title: "No runs logged",
                                   message: "Tap + to log a run. Your pace, weekly mileage, and trends build from here.")
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            summaryCard
                            filterBar
                            LazyVStack(spacing: 10) {
                                if filtered.isEmpty {
                                    Text("No runs of this type yet.").font(.subheadline)
                                        .foregroundStyle(Brand.text2).padding(.top, 20)
                                }
                                ForEach(filtered) { r in
                                    NavigationLink(value: r) { RunRow(run: r, unit: unit) }.buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Runs")
            .navigationDestination(for: Run.self) { RunDetailView(run: $0) }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Haptics.tap(); showAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Log run")
                }
            }
            .sheet(isPresented: $showAdd) { RunEditView(run: nil) }
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Eyebrow(text: "Last 7 days")
                    Text(unit.format(meters: weekMeters))
                        .font(Brand.mono(28, weight: .bold)).foregroundStyle(Brand.text)
                }
                Spacer()
                Text("\(runs.count) runs").font(Brand.mono(13)).foregroundStyle(Brand.text2)
            }
            if goalMeters > 0 {
                VStack(spacing: 4) {
                    HStack {
                        Text("Weekly goal").font(.caption).foregroundStyle(Brand.text3)
                        Spacer()
                        Text("\(Int(goalFraction * 100))% of \(Int(weeklyGoalKm)) km")
                            .font(Brand.mono(11)).foregroundStyle(Brand.text3)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Brand.hairline).frame(height: 6)
                            Capsule().fill(goalFraction >= 1 ? Brand.live : Brand.info)
                                .frame(width: max(6, geo.size.width * goalFraction), height: 6)
                        }
                    }.frame(height: 6)
                }
            }
            Chart(dailyTrend, id: \.date) { item in
                BarMark(x: .value("Day", item.date, unit: .day),
                        y: .value("Distance", unit.distance(meters: item.meters)))
                .foregroundStyle(Brand.info.gradient)
                .cornerRadius(2)
            }
            .chartXAxis { AxisMarks(values: .stride(by: .day, count: 3)) { _ in AxisGridLine(); AxisTick() } }
            .chartYAxis(.hidden)
            .frame(height: 90)
        }
        .frame(maxWidth: .infinity, alignment: .leading).glassCard(padding: 18)
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button { kindFilter = nil } label: {
                    Chip(text: "All", tint: kindFilter == nil ? Brand.text : Brand.text2)
                }
                ForEach(RunKind.allCases) { k in
                    Button { kindFilter = (kindFilter == k ? nil : k) } label: {
                        Chip(text: k.rawValue, system: k.icon, tint: kindFilter == k ? Brand.text : Brand.text2)
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }
}

private struct RunRow: View {
    let run: Run
    let unit: DistanceUnit
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: run.kind.icon).font(.title3).foregroundStyle(Brand.text)
                .frame(width: 28).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(run.name).font(.headline).foregroundStyle(Brand.text).lineLimit(1)
                HStack(spacing: 6) {
                    Chip(text: unit.format(meters: run.distanceMeters))
                    Chip(text: PaceMath.clock(run.durationSeconds))
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text(unit.paceLabel(secPerKm: run.paceSecPerKm))
                    .font(Brand.mono(14, weight: .semibold)).foregroundStyle(Brand.text)
                Text(run.date, format: .dateTime.month().day())
                    .font(Brand.mono(12)).foregroundStyle(Brand.text3)
            }
        }
        .glassCard()
    }
}
