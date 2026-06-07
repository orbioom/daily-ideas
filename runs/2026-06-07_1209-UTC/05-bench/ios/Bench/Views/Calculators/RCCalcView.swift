import SwiftUI

struct RCCalcView: View {
    @State private var rv = 10.0; @State private var rs = 1e3
    @State private var cv = 100.0; @State private var cs = 1e-9

    private var r: Double { rv * rs }
    private var c: Double { cv * cs }
    private var fc: Double? { EE.rcCutoff(r: r, c: c) }
    private var tau: Double? { EE.rcTau(r: r, c: c) }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    SectionTitle(text: "Components")
                    ScaledField(label: "R", value: $rv, scale: $rs, options: ohmScales)
                    Divider().overlay(Brand.hairline)
                    ScaledField(label: "C", value: $cv, scale: $cs, options: faradScales)
                }.glassCard()

                if let fc, let tau {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionTitle(text: "First-order RC")
                        ResultRow(label: "Cutoff frequency", value: EE.eng(fc, unit: "Hz"), accent: Brand.live)
                        Divider().overlay(Brand.hairline)
                        ResultRow(label: "Time constant τ", value: EE.duration(tau))
                        Divider().overlay(Brand.hairline)
                        ResultRow(label: "Rise to 99% (5τ)", value: EE.duration(tau * 5))
                    }.glassCard()
                    Text("Low-pass passes below the cutoff; high-pass passes above it. Both share the same −3 dB frequency.")
                        .font(.caption).foregroundStyle(Brand.text3).padding(.horizontal, 4)

                    SaveCalcButton(tool: "RC Filter",
                                   title: "RC filter",
                                   summary: "fc \(EE.eng(fc, unit: "Hz"))",
                                   detail: "R \(EE.eng(r, unit: "Ω")) · C \(EE.eng(c, unit: "F"))\nCutoff \(EE.eng(fc, unit: "Hz"))\nτ \(EE.duration(tau))")
                } else {
                    HintCard(text: "R and C must both be greater than zero.")
                }
            }
            .padding()
        }
        .navigationTitle("RC Filter")
        .navigationBarTitleDisplayMode(.inline)
        .background(Brand.pageBackground)
    }
}
