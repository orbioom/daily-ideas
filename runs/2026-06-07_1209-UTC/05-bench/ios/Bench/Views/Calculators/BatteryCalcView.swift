import SwiftUI

struct BatteryCalcView: View {
    @State private var capacity = 2000.0
    @State private var load = 150.0
    @State private var derate = 85.0

    private var hours: Double? { EE.batteryHours(capacitymAh: capacity, loadmA: load, derate: derate/100) }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    SectionTitle(text: "Battery & load")
                    NumberField(label: "Capacity", unit: "mAh", value: $capacity)
                    Divider().overlay(Brand.hairline)
                    NumberField(label: "Average load", unit: "mA", value: $load)
                    Divider().overlay(Brand.hairline)
                    HStack {
                        Text("Efficiency").foregroundStyle(Brand.text).font(.subheadline)
                        Spacer()
                        Text("\(Int(derate))%").font(Brand.mono(14, weight: .medium)).foregroundStyle(Brand.text)
                    }
                    Slider(value: $derate, in: 50...100, step: 1).tint(Brand.live)
                    Text("Real batteries deliver less than their rating under load — 80–90% is typical.")
                        .font(.caption).foregroundStyle(Brand.text3)
                }.glassCard()

                if let h = hours {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionTitle(text: "Estimated runtime")
                        ResultRow(label: "Hours", value: String(format: "%.1f h", h), accent: Brand.live)
                        Divider().overlay(Brand.hairline)
                        ResultRow(label: "Days", value: String(format: "%.1f d", h/24))
                    }.glassCard()

                    SaveCalcButton(tool: "Battery Life",
                                   title: "\(Int(capacity))mAh @ \(Int(load))mA",
                                   summary: "≈ \(String(format: "%.1f", h)) h",
                                   detail: "Capacity \(Int(capacity)) mAh · Load \(Int(load)) mA · \(Int(derate))% eff\nRuntime ≈ \(String(format: "%.1f", h)) h (\(String(format: "%.1f", h/24)) days)")
                } else {
                    HintCard(text: "Capacity and load must both be greater than zero.")
                }
            }
            .padding()
        }
        .navigationTitle("Battery Life")
        .navigationBarTitleDisplayMode(.inline)
        .background(Brand.pageBackground)
    }
}
