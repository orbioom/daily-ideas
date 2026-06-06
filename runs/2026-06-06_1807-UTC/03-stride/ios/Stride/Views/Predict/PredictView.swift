import SwiftUI

struct PredictView: View {
    @AppStorage("benchmarkMeters") private var benchmarkMeters = 10000.0
    @AppStorage("benchmarkSeconds") private var benchmarkSeconds = 3000.0
    @AppStorage("riegelExponent") private var exponent = 1.06
    @AppStorage("distanceUnit") private var unitRaw = DistanceUnit.km.rawValue

    private var unit: DistanceUnit { DistanceUnit(rawValue: unitRaw) ?? .km }
    private var valid: Bool { benchmarkMeters > 0 && benchmarkSeconds > 0 }

    private var predictions: [(name: String, meters: Double, time: Double, pace: Double)] {
        PaceMath.standardDistances.map { d in
            let t = PaceMath.riegel(t1Sec: benchmarkSeconds, d1: benchmarkMeters, d2: d.meters, exponent: exponent)
            let pace = d.meters > 0 ? t / (d.meters / 1000.0) : 0
            return (name: d.name, meters: d.meters, time: t, pace: pace)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    BenchmarkCard(meters: $benchmarkMeters, seconds: $benchmarkSeconds)

                    if valid {
                        VStack(spacing: 0) {
                            HStack {
                                Text("DISTANCE").font(Brand.mono(10, weight: .medium)).tracking(1)
                                    .foregroundStyle(Brand.text3)
                                Spacer()
                                Text("TIME").font(Brand.mono(10, weight: .medium)).tracking(1)
                                    .foregroundStyle(Brand.text3).frame(width: 90, alignment: .trailing)
                                Text("PACE").font(Brand.mono(10, weight: .medium)).tracking(1)
                                    .foregroundStyle(Brand.text3).frame(width: 84, alignment: .trailing)
                            }
                            .padding(.bottom, 8)
                            ForEach(predictions, id: \.meters) { p in
                                let isBench = abs(p.meters - benchmarkMeters) < 1
                                HStack {
                                    Text(p.name).font(.subheadline.weight(isBench ? .bold : .regular))
                                        .foregroundStyle(isBench ? Brand.magic : Brand.text)
                                    Spacer()
                                    Text(PaceMath.clock(p.time)).font(Brand.mono(15, weight: .medium))
                                        .foregroundStyle(Brand.text).frame(width: 90, alignment: .trailing)
                                    Text(unit.paceLabel(secPerKm: p.pace)).font(Brand.mono(12))
                                        .foregroundStyle(Brand.text2).frame(width: 84, alignment: .trailing)
                                }
                                .padding(.vertical, 7)
                                Divider().overlay(Brand.hairline)
                            }
                        }
                        .glassCard(padding: 18)

                        VStack(alignment: .leading, spacing: 6) {
                            Eyebrow(text: "About this estimate")
                            Text("Predictions use Riegel's formula T₂ = T₁·(D₂/D₁)^\(String(format: "%.2f", exponent)). It assumes consistent training and is most accurate near your benchmark distance — extrapolate to the marathon with care.")
                                .font(.footnote).foregroundStyle(Brand.text2)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading).glassCard()
                    } else {
                        EmptyStateView(icon: "chart.line.uptrend.xyaxis",
                                       title: "Enter a benchmark",
                                       message: "Pick a distance and time above to see predicted race times.")
                    }
                }
                .padding(16)
            }
            .background(Brand.pageBackground)
            .navigationTitle("Predict")
        }
    }
}
