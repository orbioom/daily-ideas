import SwiftUI

struct OhmCalcView: View {
    @State private var vStr = ""
    @State private var iStr = ""
    @State private var rStr = ""
    @State private var pStr = ""

    private func d(_ s: String) -> Double? { Double(s.trimmingCharacters(in: .whitespaces)) }
    private var provided: Int { [d(vStr), d(iStr), d(rStr), d(pStr)].compactMap { $0 }.count }
    private var result: EE.Ohm? {
        guard provided == 2 else { return nil }
        return EE.ohm(v: d(vStr), i: d(iStr), r: d(rStr), p: d(pStr))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    SectionTitle(text: "Enter any two")
                    field("Voltage", "V", $vStr)
                    Divider().overlay(Brand.hairline)
                    field("Current", "A", $iStr)
                    Divider().overlay(Brand.hairline)
                    field("Resistance", "Ω", $rStr)
                    Divider().overlay(Brand.hairline)
                    field("Power", "W", $pStr)
                }.glassCard()

                if let r = result {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionTitle(text: "Solution")
                        ResultRow(label: "Voltage", value: EE.eng(r.v, unit: "V"))
                        Divider().overlay(Brand.hairline)
                        ResultRow(label: "Current", value: EE.eng(r.i, unit: "A"))
                        Divider().overlay(Brand.hairline)
                        ResultRow(label: "Resistance", value: r.r.isFinite ? EE.eng(r.r, unit: "Ω") : "∞")
                        Divider().overlay(Brand.hairline)
                        ResultRow(label: "Power", value: EE.eng(r.p, unit: "W"), accent: Brand.live)
                    }.glassCard()

                    SaveCalcButton(tool: "Ohm's Law",
                                   title: "\(EE.eng(r.v, unit: "V")) · \(EE.eng(r.i, unit: "A"))",
                                   summary: "R \(r.r.isFinite ? EE.eng(r.r, unit: "Ω") : "∞") · P \(EE.eng(r.p, unit: "W"))",
                                   detail: "V \(EE.eng(r.v, unit: "V"))\nI \(EE.eng(r.i, unit: "A"))\nR \(r.r.isFinite ? EE.eng(r.r, unit: "Ω") : "∞")\nP \(EE.eng(r.p, unit: "W"))")
                } else {
                    HintCard(text: provided > 2
                             ? "You've entered \(provided) values — clear one so exactly two remain."
                             : "Enter exactly two values to solve for the rest.")
                }
            }
            .padding()
        }
        .navigationTitle("Ohm's Law")
        .navigationBarTitleDisplayMode(.inline)
        .background(Brand.pageBackground)
    }

    private func field(_ label: String, _ unit: String, _ binding: Binding<String>) -> some View {
        HStack {
            Text(label).foregroundStyle(Brand.text).font(.subheadline)
            Spacer()
            TextField("—", text: binding)
                .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                .frame(width: 110).textFieldStyle(.roundedBorder)
            Text(unit).font(Brand.mono(13)).foregroundStyle(Brand.text3).frame(width: 24, alignment: .leading)
        }
    }
}

/// A calm informational card used when there's nothing to compute yet.
struct HintCard: View {
    let text: String
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "info.circle").foregroundStyle(Brand.text3).accessibilityHidden(true)
            Text(text).font(.subheadline).foregroundStyle(Brand.text2)
            Spacer(minLength: 0)
        }.glassCard()
    }
}
