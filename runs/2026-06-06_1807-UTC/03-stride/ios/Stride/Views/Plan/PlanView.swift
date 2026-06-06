import SwiftUI

/// Race split planner: pick a distance + goal time and get a per-unit pacing table.
struct PlanView: View {
    @AppStorage("distanceUnit") private var unitRaw = DistanceUnit.km.rawValue
    @AppStorage("planMeters") private var planMeters = 21097.5
    @AppStorage("planSeconds") private var planSeconds = 6300.0   // 1:45:00 half
    @AppStorage("negativeSplit") private var negativeSplitSec = 0.0

    private var unit: DistanceUnit { DistanceUnit(rawValue: unitRaw) ?? .km }
    private var valid: Bool { planMeters > 0 && planSeconds > 0 }
    private var avgPace: Double { planMeters > 0 ? planSeconds / (planMeters / 1000.0) : 0 }

    private var rows: [(unit: Int, cumulative: Double, split: Double)] {
        PaceMath.splits(distance: planMeters, totalSec: planSeconds,
                        unitMeters: unit.unitMeters, negativeSplitSec: negativeSplitSec)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        Eyebrow(text: "Goal race")
                        Picker("Distance", selection: $planMeters) {
                            ForEach(PaceMath.standardDistances, id: \.meters) { Text($0.name).tag($0.meters) }
                        }
                        .pickerStyle(.menu)
                        HStack {
                            Text("Goal time").foregroundStyle(Brand.text2)
                            Spacer()
                            DurationField(totalSeconds: $planSeconds)
                        }
                        HStack {
                            Text("Avg pace").font(.subheadline.weight(.semibold)).foregroundStyle(Brand.text)
                            Spacer()
                            Text(unit.paceLabel(secPerKm: avgPace))
                                .font(Brand.mono(18, weight: .semibold)).foregroundStyle(Brand.magic)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading).glassCard(padding: 18)

                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Eyebrow(text: "Strategy")
                            Spacer()
                            Text(strategyLabel).font(Brand.mono(13)).foregroundStyle(Brand.text2)
                        }
                        Slider(value: $negativeSplitSec, in: -30...30, step: 2)
                        Text("Negative split shifts effort to the back half — finish each \(unit.short) up to \(Int(abs(negativeSplitSec)/2))s faster than the first.")
                            .font(.caption).foregroundStyle(Brand.text3)
                    }
                    .glassCard()

                    if valid && !rows.isEmpty {
                        VStack(spacing: 0) {
                            HStack {
                                Text(unit.short.uppercased()).font(Brand.mono(10, weight: .medium)).tracking(1)
                                    .foregroundStyle(Brand.text3)
                                Spacer()
                                Text("SPLIT").font(Brand.mono(10, weight: .medium)).tracking(1)
                                    .foregroundStyle(Brand.text3).frame(width: 80, alignment: .trailing)
                                Text("ELAPSED").font(Brand.mono(10, weight: .medium)).tracking(1)
                                    .foregroundStyle(Brand.text3).frame(width: 90, alignment: .trailing)
                            }
                            .padding(.bottom, 8)
                            ForEach(rows, id: \.unit) { r in
                                HStack {
                                    Text("\(r.unit)").font(Brand.mono(14)).foregroundStyle(Brand.text)
                                    Spacer()
                                    Text(PaceMath.paceClock(r.split)).font(Brand.mono(14))
                                        .foregroundStyle(Brand.text2).frame(width: 80, alignment: .trailing)
                                    Text(PaceMath.clock(r.cumulative)).font(Brand.mono(14, weight: .medium))
                                        .foregroundStyle(Brand.text).frame(width: 90, alignment: .trailing)
                                }
                                .padding(.vertical, 6)
                                Divider().overlay(Brand.hairline)
                            }
                        }
                        .glassCard(padding: 18)
                    } else {
                        EmptyStateView(icon: "list.number", title: "Set a goal",
                                       message: "Pick a distance and goal time to build a split plan.")
                    }
                }
                .padding(16)
            }
            .background(Brand.pageBackground)
            .navigationTitle("Race Plan")
        }
    }

    private var strategyLabel: String {
        if negativeSplitSec > 1 { return "Negative split" }
        if negativeSplitSec < -1 { return "Positive split" }
        return "Even pace"
    }
}
