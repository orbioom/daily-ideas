import SwiftUI

struct DividerCalcView: View {
    @State private var mode = 0   // 0 = find Vout, 1 = find R2
    @State private var vin = 9.0
    @State private var r1v = 10.0; @State private var r1s = 1e3
    @State private var r2v = 10.0; @State private var r2s = 1e3
    @State private var targetVout = 3.3

    private var r1: Double { r1v * r1s }
    private var r2: Double { r2v * r2s }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Picker("Mode", selection: $mode) {
                    Text("Find Vout").tag(0); Text("Find R2").tag(1)
                }.pickerStyle(.segmented)

                VStack(alignment: .leading, spacing: 12) {
                    SectionTitle(text: "Inputs")
                    NumberField(label: "Input voltage", unit: "V", value: $vin)
                    Divider().overlay(Brand.hairline)
                    ScaledField(label: "R1 (top)", value: $r1v, scale: $r1s, options: ohmScales)
                    if mode == 0 {
                        Divider().overlay(Brand.hairline)
                        ScaledField(label: "R2 (bottom)", value: $r2v, scale: $r2s, options: ohmScales)
                    } else {
                        Divider().overlay(Brand.hairline)
                        NumberField(label: "Target Vout", unit: "V", value: $targetVout)
                    }
                }.glassCard()

                resultCard
            }
            .padding()
        }
        .navigationTitle("Voltage Divider")
        .navigationBarTitleDisplayMode(.inline)
        .background(Brand.pageBackground)
    }

    @ViewBuilder private var resultCard: some View {
        if mode == 0 {
            if let vout = EE.dividerVout(vin: vin, r1: r1, r2: r2) {
                VStack(alignment: .leading, spacing: 10) {
                    SectionTitle(text: "Output")
                    ResultRow(label: "Vout", value: EE.eng(vout, unit: "V"), accent: Brand.live)
                    Divider().overlay(Brand.hairline)
                    ResultRow(label: "Ratio", value: "\(EE.trimmed(r1+r2 > 0 ? r2/(r1+r2) : 0, places: 3))")
                    Divider().overlay(Brand.hairline)
                    ResultRow(label: "Divider current", value: EE.eng(r1+r2 > 0 ? vin/(r1+r2) : 0, unit: "A"))
                }.glassCard()
                SaveCalcButton(tool: "Voltage Divider",
                               title: "Vout from R1/R2",
                               summary: "Vout \(EE.eng(vout, unit: "V"))",
                               detail: "Vin \(EE.eng(vin, unit: "V"))\nR1 \(EE.eng(r1, unit: "Ω")) · R2 \(EE.eng(r2, unit: "Ω"))\nVout \(EE.eng(vout, unit: "V"))")
            } else {
                HintCard(text: "Set R1 and R2 to non-zero values.")
            }
        } else {
            if let r2calc = EE.dividerR2(vin: vin, r1: r1, vout: targetVout) {
                VStack(alignment: .leading, spacing: 10) {
                    SectionTitle(text: "Required R2")
                    ResultRow(label: "Exact R2", value: EE.eng(r2calc, unit: "Ω"))
                    Divider().overlay(Brand.hairline)
                    ResultRow(label: "Nearest E12", value: EE.eng(EE.nearestStandard(r2calc), unit: "Ω"), accent: Brand.live)
                }.glassCard()
                SaveCalcButton(tool: "Voltage Divider",
                               title: "R2 for \(EE.trimmed(targetVout, places: 3))V",
                               summary: "R2 ≈ \(EE.eng(EE.nearestStandard(r2calc), unit: "Ω"))",
                               detail: "Vin \(EE.eng(vin, unit: "V")) · R1 \(EE.eng(r1, unit: "Ω"))\nTarget Vout \(EE.eng(targetVout, unit: "V"))\nR2 exact \(EE.eng(r2calc, unit: "Ω")) → E12 \(EE.eng(EE.nearestStandard(r2calc), unit: "Ω"))")
            } else {
                HintCard(text: "Target Vout must be positive and below the input voltage.")
            }
        }
    }
}
