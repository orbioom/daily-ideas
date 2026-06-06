import SwiftUI

/// Nitrox & no-stop planner. Everything updates live as you change inputs.
struct PlannerView: View {
    @AppStorage("unitSystem") private var unitRaw = UnitSystem.metric.rawValue
    @AppStorage("defaultO2") private var defaultO2 = 32
    @AppStorage("ppO2Limit") private var ppO2Limit = 1.4

    @State private var depthText = "30"
    @State private var o2 = 32

    private var unit: UnitSystem { UnitSystem(rawValue: unitRaw) ?? .metric }
    private var depthM: Double { unit.depthToM(parse(depthText)) }

    private var mod: Double { DiveMath.mod(oxygenPercent: o2, ppO2Max: ppO2Limit) }
    private var ppo2: Double { DiveMath.ppO2(oxygenPercent: o2, atDepth: depthM) }
    private var ead: Double { DiveMath.ead(oxygenPercent: o2, atDepth: depthM) }
    private var ndl: Int { DiveMath.ndl(oxygenPercent: o2, atDepth: depthM) }
    private var bestMix: Int { DiveMath.bestMix(forDepth: depthM, ppO2Max: ppO2Limit) }
    private var withinMOD: Bool { depthM <= mod + 0.05 }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        inputCard
                        resultCard
                        bestMixCard
                        Text("Recreational planning figures only. Always cross-check with your training, certified tables, and dive computer.")
                            .font(.caption).foregroundStyle(Brand.text3)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 8).padding(.bottom, 28)
                }
            }
            .navigationTitle("Planner")
            .onAppear { o2 = defaultO2 }
        }
    }

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Planned depth (\(unit.depthUnit))").font(.subheadline).foregroundStyle(Brand.text)
                Spacer()
                TextField("0", text: $depthText).keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing).frame(width: 90).font(Brand.mono(18))
            }
            Divider().overlay(Brand.hairline)
            Stepper(value: $o2, in: 21...40) {
                HStack {
                    Text("Gas").font(.subheadline).foregroundStyle(Brand.text)
                    Spacer()
                    Text(BreathingGas(oxygenPercent: o2).label).font(Brand.mono(15, weight: .medium)).foregroundStyle(Brand.live)
                }
            }
            Picker("ppO₂ limit", selection: $ppO2Limit) {
                Text("1.4 (working)").tag(1.4)
                Text("1.6 (deco/contingency)").tag(1.6)
            }.pickerStyle(.segmented)
        }
        .glassCard()
    }

    private var resultCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow(text: "At \(Int(unit.depthOut(depthM).rounded())) \(unit.depthUnit) on \(BreathingGas(oxygenPercent: o2).label)")
            HStack(spacing: 10) {
                StatTile(value: depthLabel(mod), label: "MOD (ppO₂ \(String(format: "%.1f", ppO2Limit)))",
                         tint: withinMOD ? Brand.live : Brand.danger)
                StatTile(value: String(format: "%.2f", ppo2), label: "ppO₂ here",
                         tint: ppo2 > ppO2Limit ? Brand.danger : Brand.text)
            }
            HStack(spacing: 10) {
                StatTile(value: depthLabel(ead), label: "Equiv. air depth")
                StatTile(value: ndl > 0 ? "\(ndl) min" : "—", label: "No-stop limit", tint: Brand.info)
            }
            if !withinMOD {
                Label("This depth is past the MOD for \(BreathingGas(oxygenPercent: o2).label). Use a leaner mix or go shallower.",
                      systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote).foregroundStyle(Brand.danger)
            } else if ndl == 0 {
                Label("Beyond the recreational no-stop range at this equivalent depth.", systemImage: "info.circle")
                    .font(.footnote).foregroundStyle(Brand.warn)
            }
        }
        .glassCard()
    }

    private var bestMixCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Eyebrow(text: "Best mix for this depth")
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(BreathingGas(oxygenPercent: bestMix).label)
                    .font(Brand.mono(28, weight: .bold)).foregroundStyle(Brand.text)
                Text("keeps ppO₂ at \(String(format: "%.1f", ppO2Limit)) at \(Int(unit.depthOut(depthM).rounded())) \(unit.depthUnit)")
                    .font(.subheadline).foregroundStyle(Brand.text2)
            }
        }
        .glassCard()
    }

    private func depthLabel(_ m: Double) -> String { "\(Int(unit.depthOut(m).rounded())) \(unit.depthUnit)" }
    private func parse(_ s: String) -> Double { max(0, Double(s.replacingOccurrences(of: ",", with: ".")) ?? 0) }
}
