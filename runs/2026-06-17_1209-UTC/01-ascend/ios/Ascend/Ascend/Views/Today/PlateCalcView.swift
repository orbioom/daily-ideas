import SwiftUI

/// Barbell plate calculator — greedy per-side breakdown using the user's plate set.
struct PlateCalcView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @State private var targetText = "60"

    private var unit: WeightUnit { settings.unit }

    private var targetKg: Double {
        let v = Double(targetText.replacingOccurrences(of: ",", with: ".")) ?? 0
        return Units.fromDisplay(max(v, 0), unit: unit)
    }

    private var result: PlateCalculator.Result {
        PlateCalculator.breakdown(targetKg: targetKg,
                                  barKg: max(settings.barWeightKg, 0),
                                  availableKg: settings.plateSetKg)
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    inputCard
                    barView
                    breakdownCard
                }
                .padding(20)
            }
        }
        .navigationTitle("Plate Math")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
        }
    }

    private var inputCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                Text("Target weight")
                    .font(Theme.rounded(13, .semibold))
                    .foregroundStyle(Theme.inkSoft)
                HStack {
                    TextField("0", text: $targetText)
                        .keyboardType(.decimalPad)
                        .font(Theme.num(34, .heavy))
                        .foregroundStyle(Theme.ink)
                    Text(unit.label)
                        .font(Theme.rounded(18, .semibold))
                        .foregroundStyle(Theme.inkFaint)
                }
                Text("Bar: \(settings.weight(settings.barWeightKg))")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkFaint)
            }
        }
    }

    private var barView: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Load each side")
                    .font(Theme.rounded(13, .semibold))
                    .foregroundStyle(Theme.inkSoft)
                if result.perSide.isEmpty {
                    Text("Just the bar — no plates needed.")
                        .font(Theme.rounded(15))
                        .foregroundStyle(Theme.inkSoft)
                } else {
                    HStack(alignment: .bottom, spacing: 6) {
                        ForEach(Array(result.perSide.enumerated()), id: \.offset) { _, plate in
                            plateChip(plate)
                        }
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Per side: " + perSideSpoken)
    }

    private func plateChip(_ kg: Double) -> some View {
        let h = 40 + min(kg, 30) * 2.2
        return VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(Theme.accent.gradient)
                .frame(width: 26, height: h)
            Text(Units.formatNumber(kg, unit: unit))
                .font(Theme.rounded(11, .bold))
                .foregroundStyle(Theme.ink)
                .monospacedDigit()
        }
    }

    private var breakdownCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                row("Achievable", settings.weight(result.achievableTotalKg), Theme.ink)
                if !result.isExact {
                    row("Short by", settings.weight(result.remainderKg), Theme.bad)
                    Text("Adjust the target or add smaller plates in Settings.")
                        .font(Theme.rounded(12))
                        .foregroundStyle(Theme.inkFaint)
                } else {
                    Label("Exact match", systemImage: "checkmark.seal.fill")
                        .font(Theme.rounded(13, .semibold))
                        .foregroundStyle(Theme.good)
                }
            }
        }
    }

    private func row(_ title: String, _ value: String, _ color: Color) -> some View {
        HStack {
            Text(title).font(Theme.rounded(15)).foregroundStyle(Theme.inkSoft)
            Spacer()
            Text(value).font(Theme.num(18, .bold)).foregroundStyle(color).monospacedDigit()
        }
    }

    private var perSideSpoken: String {
        if result.perSide.isEmpty { return "bar only" }
        return result.perSide.map { Units.formatWeight($0, unit: unit) }.joined(separator: ", ")
    }
}
