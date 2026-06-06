import SwiftUI

struct PacesView: View {
    @AppStorage("benchmarkMeters") private var benchmarkMeters = 10000.0
    @AppStorage("benchmarkSeconds") private var benchmarkSeconds = 3000.0
    @AppStorage("distanceUnit") private var unitRaw = DistanceUnit.km.rawValue

    private var unit: DistanceUnit { DistanceUnit(rawValue: unitRaw) ?? .km }
    private var vdot: Double { PaceMath.vdot(distance: benchmarkMeters, timeSec: benchmarkSeconds) }
    private var valid: Bool { vdot > 0 }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    BenchmarkCard(meters: $benchmarkMeters, seconds: $benchmarkSeconds)

                    if valid {
                        VStack(spacing: 6) {
                            Text("VDOT").font(Brand.mono(11, weight: .medium)).tracking(1.5)
                                .foregroundStyle(Brand.text3)
                            Text(String(format: "%.1f", vdot))
                                .font(Brand.mono(40, weight: .bold)).foregroundStyle(Brand.text)
                        }
                        .frame(maxWidth: .infinity).glassCard(padding: 20)

                        VStack(spacing: 10) {
                            ForEach(PaceMath.Zone.allCases) { zone in
                                zoneRow(zone)
                            }
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Eyebrow(text: "How to use these")
                            Text("Run most miles at Easy. Save Threshold for tempo work, Interval for VO₂max reps, and Repetition for short, fast strides. Paces are derived from your VDOT using Daniels' running model.")
                                .font(.footnote).foregroundStyle(Brand.text2)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading).glassCard()
                    } else {
                        EmptyStateView(icon: "speedometer",
                                       title: "Enter a benchmark",
                                       message: "Pick a recent race result above to compute your training paces.")
                    }
                }
                .padding(16)
            }
            .background(Brand.pageBackground)
            .navigationTitle("Training Paces")
        }
    }

    private func zoneRow(_ zone: PaceMath.Zone) -> some View {
        let secPerKm = PaceMath.paceSecPerKm(vdot: vdot, zone: zone)
        return HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text(zone.rawValue).font(.headline).foregroundStyle(Brand.text)
                Text(zone.blurb).font(.caption).foregroundStyle(Brand.text2).lineLimit(2)
            }
            Spacer()
            Text(unit.paceLabel(secPerKm: secPerKm))
                .font(Brand.mono(18, weight: .semibold)).foregroundStyle(Brand.magic)
        }
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(zone.rawValue) pace \(unit.paceLabel(secPerKm: secPerKm))")
    }
}
