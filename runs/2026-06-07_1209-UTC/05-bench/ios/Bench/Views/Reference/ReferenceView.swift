import SwiftUI

/// A read-only quick reference: colour codes, E12 values, SI prefixes and the
/// formulas behind the calculators.
struct ReferenceView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    colorChart
                    eSeriesCard
                    siPrefixCard
                    formulaCard
                }
                .padding()
            }
            .navigationTitle("Reference")
            .background(Brand.pageBackground)
        }
    }

    private var colorChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: "Resistor colour code")
            ForEach(EE.bandColors.indices, id: \.self) { i in
                let name = EE.bandColors[i]
                HStack(spacing: 10) {
                    Circle().fill(swatch(name)).frame(width: 16, height: 16)
                        .overlay(Circle().strokeBorder(Brand.hairline, lineWidth: 1))
                    Text(name).font(.subheadline).foregroundStyle(Brand.text)
                    Spacer()
                    Text("digit \(i)").font(Brand.mono(12)).foregroundStyle(Brand.text3)
                    Text("×10^\(i)").font(Brand.mono(12)).foregroundStyle(Brand.text2).frame(width: 56, alignment: .trailing)
                }
                if i != EE.bandColors.count - 1 { Divider().overlay(Brand.hairline) }
            }
            Text("Gold ×0.1 (±5%) · Silver ×0.01 (±10%)")
                .font(.caption).foregroundStyle(Brand.text3).padding(.top, 4)
        }.glassCard()
    }

    private var eSeriesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: "E12 standard values")
            Text(EE.e12.map { EE.trimmed($0, places: 2) }.joined(separator: "  ·  "))
                .font(Brand.mono(14)).foregroundStyle(Brand.text)
            Text("Repeat ×1, ×10, ×100 … across each decade (±10% tolerance).")
                .font(.caption).foregroundStyle(Brand.text3)
        }.glassCard()
    }

    private var siPrefixCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(text: "SI prefixes")
            ForEach(prefixes.indices, id: \.self) { i in
                HStack {
                    Text(prefixes[i].0).font(.subheadline).foregroundStyle(Brand.text)
                    Spacer()
                    Text(prefixes[i].1).font(Brand.mono(13)).foregroundStyle(Brand.text2)
                }
                if i != prefixes.count - 1 { Divider().overlay(Brand.hairline) }
            }
        }.glassCard()
    }

    private var formulaCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(text: "Formulas")
            ForEach(formulas.indices, id: \.self) { i in
                VStack(alignment: .leading, spacing: 2) {
                    Text(formulas[i].0).font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                    Text(formulas[i].1).font(Brand.mono(13)).foregroundStyle(Brand.text2)
                }
                if i != formulas.count - 1 { Divider().overlay(Brand.hairline) }
            }
        }.glassCard()
    }

    private let prefixes: [(String, String)] = [
        ("Tera (T)", "10¹²"), ("Giga (G)", "10⁹"), ("Mega (M)", "10⁶"),
        ("kilo (k)", "10³"), ("milli (m)", "10⁻³"), ("micro (µ)", "10⁻⁶"),
        ("nano (n)", "10⁻⁹"), ("pico (p)", "10⁻¹²")
    ]
    private let formulas: [(String, String)] = [
        ("Ohm's law", "V = I · R   P = V · I"),
        ("LED resistor", "R = (Vsupply − Vf) / I"),
        ("Voltage divider", "Vout = Vin · R2 / (R1 + R2)"),
        ("555 astable", "f = 1.44 / ((R1 + 2·R2) · C)"),
        ("555 duty", "D = (R1 + R2) / (R1 + 2·R2)"),
        ("RC cutoff", "fc = 1 / (2π · R · C)"),
        ("Battery life", "t = (capacity / load) · efficiency")
    ]

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
        default: return Brand.text3
        }
    }
}
