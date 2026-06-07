import SwiftUI

struct Timer555CalcView: View {
    @State private var r1v = 1.0;  @State private var r1s = 1e3
    @State private var r2v = 10.0; @State private var r2s = 1e3
    @State private var cv = 10.0;  @State private var cs = 1e-6

    private var r1: Double { r1v * r1s }
    private var r2: Double { r2v * r2s }
    private var c: Double { cv * cs }
    private var result: EE.Astable? { EE.ne555Astable(r1: r1, r2: r2, c: c) }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    SectionTitle(text: "Astable components")
                    ScaledField(label: "R1", value: $r1v, scale: $r1s, options: ohmScales)
                    Divider().overlay(Brand.hairline)
                    ScaledField(label: "R2", value: $r2v, scale: $r2s, options: ohmScales)
                    Divider().overlay(Brand.hairline)
                    ScaledField(label: "C", value: $cv, scale: $cs, options: faradScales)
                }.glassCard()

                if let a = result {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionTitle(text: "Output")
                        ResultRow(label: "Frequency", value: EE.eng(a.freq, unit: "Hz"), accent: Brand.live)
                        Divider().overlay(Brand.hairline)
                        ResultRow(label: "Period", value: EE.duration(a.tHigh + a.tLow))
                        Divider().overlay(Brand.hairline)
                        ResultRow(label: "Duty cycle", value: "\(EE.trimmed(a.duty, places: 3))%")
                        Divider().overlay(Brand.hairline)
                        ResultRow(label: "Time high", value: EE.duration(a.tHigh))
                        Divider().overlay(Brand.hairline)
                        ResultRow(label: "Time low", value: EE.duration(a.tLow))
                    }.glassCard()

                    SaveCalcButton(tool: "555 Astable Timer",
                                   title: "555 astable",
                                   summary: "f \(EE.eng(a.freq, unit: "Hz")) · \(EE.trimmed(a.duty, places: 3))%",
                                   detail: "R1 \(EE.eng(r1, unit: "Ω")) · R2 \(EE.eng(r2, unit: "Ω")) · C \(EE.eng(c, unit: "F"))\nf \(EE.eng(a.freq, unit: "Hz"))\nDuty \(EE.trimmed(a.duty, places: 3))%\ntHigh \(EE.duration(a.tHigh)) · tLow \(EE.duration(a.tLow))")
                } else {
                    HintCard(text: "R1, R2 and C must all be greater than zero.")
                }
            }
            .padding()
        }
        .navigationTitle("555 Astable")
        .navigationBarTitleDisplayMode(.inline)
        .background(Brand.pageBackground)
    }
}
