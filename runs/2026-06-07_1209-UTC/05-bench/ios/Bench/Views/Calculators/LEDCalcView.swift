import SwiftUI

struct LEDCalcView: View {
    @AppStorage("bench.ledCurrent") private var defaultCurrent = 20.0
    @State private var supply = 5.0
    @State private var forward = 2.0
    @State private var current = 20.0
    @State private var loaded = false

    private var result: EE.LED? { EE.ledResistor(supply: supply, forward: forward, currentmA: current) }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    SectionTitle(text: "LED & supply")
                    NumberField(label: "Supply voltage", unit: "V", value: $supply)
                    Divider().overlay(Brand.hairline)
                    NumberField(label: "LED forward voltage", unit: "V", value: $forward)
                    Divider().overlay(Brand.hairline)
                    NumberField(label: "LED current", unit: "mA", value: $current)
                }.glassCard()

                if let r = result {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionTitle(text: "Series resistor")
                        ResultRow(label: "Exact value", value: EE.eng(r.resistance, unit: "Ω"))
                        Divider().overlay(Brand.hairline)
                        ResultRow(label: "Nearest E12", value: EE.eng(r.standard, unit: "Ω"), accent: Brand.live)
                        Divider().overlay(Brand.hairline)
                        ResultRow(label: "Resistor power", value: EE.eng(r.power, unit: "W"))
                        Divider().overlay(Brand.hairline)
                        ResultRow(label: "Voltage across R", value: EE.eng(r.headroom, unit: "V"))
                    }.glassCard()

                    SaveCalcButton(tool: "LED Series Resistor",
                                   title: "\(EE.trimmed(supply, places: 3))V LED @ \(Int(current))mA",
                                   summary: "R ≈ \(EE.eng(r.standard, unit: "Ω"))",
                                   detail: "Supply \(EE.trimmed(supply, places: 3)) V · Vf \(EE.trimmed(forward, places: 3)) V · \(Int(current)) mA\nExact \(EE.eng(r.resistance, unit: "Ω")) → E12 \(EE.eng(r.standard, unit: "Ω"))\nResistor power \(EE.eng(r.power, unit: "W"))")
                } else {
                    HintCard(text: "Supply voltage must be greater than the LED's forward voltage, and current above zero.")
                }
            }
            .padding()
        }
        .navigationTitle("LED Resistor")
        .navigationBarTitleDisplayMode(.inline)
        .background(Brand.pageBackground)
        .onAppear { if !loaded { current = defaultCurrent; loaded = true } }
    }
}
