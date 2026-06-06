import SwiftUI
import SwiftData

/// Estimates yarn needed for a rectangular piece and checks it against a stash yarn.
struct YardageEstimatorView: View {
    @Query(sort: \StashYarn.createdAt, order: .reverse) private var yarns: [StashYarn]
    @AppStorage("unitSystem") private var unitRaw = UnitSystem.imperial.rawValue

    @State private var weight: YarnWeight = .medium
    @State private var widthText = ""
    @State private var lengthText = ""
    @State private var easePercent: Double = 15
    @State private var checkYarn: StashYarn?

    private var unit: UnitSystem { UnitSystem(rawValue: unitRaw) ?? .imperial }
    private var widthIn: Double { GaugeMath.inches(from: parse(widthText), unit: unit) }
    private var lengthIn: Double { GaugeMath.inches(from: parse(lengthText), unit: unit) }
    private var yardsNeeded: Double {
        GaugeMath.yards(weight: weight, widthInches: widthIn, lengthInches: lengthIn, ease: easePercent / 100)
    }
    private var hasResult: Bool { yardsNeeded > 0 }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                inputCard
                resultCard
                if !yarns.isEmpty { stashCheckCard }
            }
            .padding(.horizontal, 16).padding(.vertical, 8).padding(.bottom, 28)
        }
        .background(Brand.pageBackground)
        .navigationTitle("Yardage")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { if checkYarn == nil { checkYarn = yarns.first; if let y = checkYarn { weight = y.weight } } }
    }

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Picker("Yarn weight", selection: $weight) {
                ForEach(YarnWeight.allCases) { Text($0.name).tag($0) }
            }
            .pickerStyle(.menu)
            Divider().overlay(Brand.hairline)
            field("Width (\(unit.shortUnit))", $widthText)
            field("Length (\(unit.shortUnit))", $lengthText)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Safety margin").font(.subheadline).foregroundStyle(Brand.text)
                    Spacer()
                    Text("\(Int(easePercent))%").font(Brand.mono(15)).foregroundStyle(Brand.text2)
                }
                Slider(value: $easePercent, in: 0...50, step: 5)
                    .accessibilityValue("\(Int(easePercent)) percent")
            }
        }
        .glassCard()
    }

    private var resultCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow(text: "Estimated need")
            if hasResult {
                HStack(spacing: 10) {
                    StatTile(value: "\(Int(yardsNeeded.rounded()))", label: "Yards", tint: Brand.text)
                    StatTile(value: String(format: "%.0f", yardsNeeded * 0.9144), label: "Metres")
                }
                Text("Plain stockinette / single-crochet estimate for a \(weight.name.lowercased())-weight yarn, including a \(Int(easePercent))% margin. Textured stitches use more.")
                    .font(.footnote).foregroundStyle(Brand.text3)
            } else {
                Text("Enter a width and length to estimate the yarn needed.")
                    .font(.subheadline).foregroundStyle(Brand.text2)
            }
        }
        .glassCard()
    }

    private var stashCheckCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow(text: "Check against stash")
            Picker("Yarn", selection: Binding(
                get: { checkYarn?.id }, set: { id in checkYarn = yarns.first { $0.id == id } })) {
                ForEach(yarns) { Text($0.name.isEmpty ? "Unnamed" : $0.name).tag(Optional($0.id)) }
            }
            .pickerStyle(.menu)
            if let y = checkYarn, hasResult {
                let enough = y.totalYards >= yardsNeeded
                HStack(spacing: 10) {
                    Image(systemName: enough ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(enough ? Brand.live : Brand.warn)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(enough ? "You have enough" : "Might be short")
                            .font(.headline).foregroundStyle(Brand.text)
                        Text(detail(for: y, enough: enough))
                            .font(.subheadline).foregroundStyle(Brand.text2)
                    }
                    Spacer()
                }
            } else if checkYarn != nil {
                Text("Enter a size above to compare.").font(.subheadline).foregroundStyle(Brand.text2)
            }
        }
        .glassCard()
    }

    private func detail(for y: StashYarn, enough: Bool) -> String {
        let have = Int(y.totalYards.rounded())
        let need = Int(yardsNeeded.rounded())
        if enough {
            return "Have \(have) yd, need ~\(need) yd."
        } else {
            let short = max(0, need - have)
            let extra = GaugeMath.skeinsNeeded(yardsNeeded: Double(short), yardsPerSkein: y.yardsPerSkein)
            let skeins = extra > 0 ? " (≈\(extra) more skein\(extra == 1 ? "" : "s"))" : ""
            return "Have \(have) yd, need ~\(need) yd — short \(short) yd\(skeins)."
        }
    }

    private func field(_ label: String, _ binding: Binding<String>) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundStyle(Brand.text)
            Spacer()
            TextField("0", text: binding).keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing).frame(width: 90).font(Brand.mono(16))
        }
    }
    private func parse(_ s: String) -> Double { max(0, Double(s.replacingOccurrences(of: ",", with: ".")) ?? 0) }
}
