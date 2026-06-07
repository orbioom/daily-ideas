import SwiftUI

struct ResistorCalcView: View {
    @State private var bandCount = 4
    @State private var d1 = "Yellow"
    @State private var d2 = "Violet"
    @State private var d3 = "Black"   // 3rd significant digit (5-band)
    @State private var mult = "Red"
    @State private var tol = "Gold"

    private var digits: [String] { bandCount == 5 ? [d1, d2, d3] : [d1, d2] }
    private var decoded: (ohms: Double, tol: Double) {
        EE.decodeResistor(digits: digits, multiplierColor: mult, toleranceColor: tol)
    }
    private var low: Double { decoded.ohms * (1 - decoded.tol/100) }
    private var high: Double { decoded.ohms * (1 + decoded.tol/100) }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                bandPreview
                VStack(alignment: .leading, spacing: 12) {
                    SectionTitle(text: "Bands")
                    Picker("Bands", selection: $bandCount) {
                        Text("4-band").tag(4); Text("5-band").tag(5)
                    }.pickerStyle(.segmented)
                    Divider().overlay(Brand.hairline)
                    colorPicker("Digit 1", $d1, EE.bandColors)
                    colorPicker("Digit 2", $d2, EE.bandColors)
                    if bandCount == 5 { colorPicker("Digit 3", $d3, EE.bandColors) }
                    colorPicker("Multiplier", $mult, EE.multiplierColors)
                    colorPicker("Tolerance", $tol, EE.toleranceColors)
                }.glassCard()

                VStack(alignment: .leading, spacing: 10) {
                    SectionTitle(text: "Value")
                    ResultRow(label: "Resistance", value: EE.eng(decoded.ohms, unit: "Ω"), accent: Brand.live)
                    Divider().overlay(Brand.hairline)
                    ResultRow(label: "Tolerance", value: "±\(EE.trimmed(decoded.tol, places: 3))%")
                    Divider().overlay(Brand.hairline)
                    ResultRow(label: "Range", value: "\(EE.eng(low, unit: "Ω")) – \(EE.eng(high, unit: "Ω"))")
                }.glassCard()

                SaveCalcButton(tool: "Resistor Colour Code",
                               title: EE.eng(decoded.ohms, unit: "Ω"),
                               summary: "±\(EE.trimmed(decoded.tol, places: 3))% · \(digits.joined(separator: "-"))",
                               detail: "Bands: \(digits.joined(separator: ", ")) | mult \(mult) | tol \(tol)\nValue \(EE.eng(decoded.ohms, unit: "Ω")) ±\(EE.trimmed(decoded.tol, places: 3))%\nRange \(EE.eng(low, unit: "Ω")) – \(EE.eng(high, unit: "Ω"))")
            }
            .padding()
        }
        .navigationTitle("Resistor Colour")
        .navigationBarTitleDisplayMode(.inline)
        .background(Brand.pageBackground)
    }

    private var bandPreview: some View {
        let bands = digits + [mult, tol]
        return HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 4).fill(Color(hex: 0xD8C9A0)).frame(height: 44)
                .overlay(
                    HStack(spacing: 8) {
                        ForEach(Array(bands.enumerated()), id: \.offset) { _, c in
                            RoundedRectangle(cornerRadius: 2).fill(swatch(c)).frame(width: 12)
                        }
                    }.padding(.horizontal, 18)
                )
        }
        .accessibilityHidden(true)
    }

    private func colorPicker(_ label: String, _ binding: Binding<String>, _ options: [String]) -> some View {
        HStack {
            Circle().fill(swatch(binding.wrappedValue)).frame(width: 16, height: 16)
                .overlay(Circle().strokeBorder(Brand.hairline, lineWidth: 1))
            Text(label).foregroundStyle(Brand.text).font(.subheadline)
            Spacer()
            Picker(label, selection: binding) {
                ForEach(options, id: \.self) { Text($0).tag($0) }
            }.pickerStyle(.menu).tint(Brand.text2)
        }
    }

    private func swatch(_ name: String) -> Color {
        switch name {
        case "Black": return Color(hex: 0x1A1A1A)
        case "Brown": return Color(hex: 0x7A4B2B)
        case "Red": return Color(hex: 0xC0392B)
        case "Orange": return Color(hex: 0xE08A2B)
        case "Yellow": return Color(hex: 0xE0C03E)
        case "Green": return Color(hex: 0x3E9E78)
        case "Blue": return Color(hex: 0x3A6EA8)
        case "Violet": return Color(hex: 0x8A5BB0)
        case "Grey": return Color(hex: 0x8B8FA3)
        case "White": return Color(hex: 0xF2F3F8)
        case "Gold": return Color(hex: 0xC8A24A)
        case "Silver": return Color(hex: 0xC0C4CC)
        default: return Brand.text3
        }
    }
}
