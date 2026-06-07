import SwiftUI

/// The seven calculators offered on the bench.
enum ToolKind: String, CaseIterable, Identifiable {
    case ohm = "Ohm's Law"
    case resistor = "Resistor Colour Code"
    case led = "LED Series Resistor"
    case divider = "Voltage Divider"
    case timer555 = "555 Astable Timer"
    case rc = "RC Filter"
    case battery = "Battery Life"

    var id: String { rawValue }
    var blurb: String {
        switch self {
        case .ohm: return "Solve V, I, R and power from any two"
        case .resistor: return "Decode 4/5-band colours to a value"
        case .led: return "Dropper resistor for an LED"
        case .divider: return "Vout from R1/R2, or solve R2"
        case .timer555: return "Frequency and duty from R1, R2, C"
        case .rc: return "Cutoff frequency and time constant"
        case .battery: return "Runtime from capacity and load"
        }
    }
    var symbol: String {
        switch self {
        case .ohm: return "bolt.circle"
        case .resistor: return "paintpalette"
        case .led: return "lightbulb"
        case .divider: return "arrow.triangle.branch"
        case .timer555: return "waveform.path"
        case .rc: return "line.diagonal"
        case .battery: return "battery.50"
        }
    }
}

struct CalculatorsView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(ToolKind.allCases) { tool in
                        NavigationLink { destination(tool) } label: { toolRow(tool) }
                            .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("Calculators")
            .background(Brand.pageBackground)
        }
    }

    @ViewBuilder private func destination(_ tool: ToolKind) -> some View {
        switch tool {
        case .ohm: OhmCalcView()
        case .resistor: ResistorCalcView()
        case .led: LEDCalcView()
        case .divider: DividerCalcView()
        case .timer555: Timer555CalcView()
        case .rc: RCCalcView()
        case .battery: BatteryCalcView()
        }
    }

    private func toolRow(_ tool: ToolKind) -> some View {
        HStack(spacing: 14) {
            Image(systemName: tool.symbol)
                .font(.title2).foregroundStyle(Brand.text).frame(width: 36)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(tool.rawValue).font(.headline).foregroundStyle(Brand.text)
                Text(tool.blurb).font(.subheadline).foregroundStyle(Brand.text2)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(Brand.text3)
        }
        .glassCard()
    }
}

// MARK: - Shared calculator building blocks

/// A labelled numeric input with a trailing unit.
struct NumberField: View {
    let label: String
    var unit: String = ""
    @Binding var value: Double
    var body: some View {
        HStack {
            Text(label).foregroundStyle(Brand.text).font(.subheadline)
            Spacer()
            TextField("0", value: $value, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 110)
                .textFieldStyle(.roundedBorder)
            if !unit.isEmpty {
                Text(unit).font(Brand.mono(13)).foregroundStyle(Brand.text3).frame(width: 28, alignment: .leading)
            }
        }
    }
}

/// A result line: label left, mono value right.
struct ResultRow: View {
    let label: String
    let value: String
    var accent: Color = Brand.text
    var body: some View {
        HStack {
            Text(label).foregroundStyle(Brand.text2).font(.subheadline)
            Spacer()
            Text(value).font(Brand.mono(16, weight: .semibold)).foregroundStyle(accent)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

/// A numeric input with an SI-scale picker. The parent owns `value` (the typed
/// number) and `scale` (the multiplier); the base value is `value * scale`.
struct ScaledField: View {
    let label: String
    @Binding var value: Double
    @Binding var scale: Double
    let options: [(String, Double)]
    var body: some View {
        HStack {
            Text(label).foregroundStyle(Brand.text).font(.subheadline)
            Spacer()
            TextField("0", value: $value, format: .number)
                .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                .frame(width: 90).textFieldStyle(.roundedBorder)
            Picker(label, selection: $scale) {
                ForEach(options.indices, id: \.self) { i in
                    Text(options[i].0).tag(options[i].1)
                }
            }.pickerStyle(.menu).tint(Brand.text2).frame(width: 64)
        }
    }
}

let ohmScales: [(String, Double)] = [("Ω", 1), ("kΩ", 1e3), ("MΩ", 1e6)]
let faradScales: [(String, Double)] = [("pF", 1e-12), ("nF", 1e-9), ("µF", 1e-6)]

/// Save-to-notebook button shared by calculators.
struct SaveCalcButton: View {
    @Environment(\.modelContext) private var context
    let tool: String
    let title: String
    let summary: String
    let detail: String
    var enabled: Bool = true
    @State private var saved = false

    var body: some View {
        Button {
            let calc = SavedCalc(tool: tool, title: title, summary: summary, detail: detail)
            context.insert(calc)
            try? context.save()
            Haptics.success()
            withAnimation(Brand.ease()) { saved = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { withAnimation(Brand.ease()) { saved = false } }
        } label: {
            Label(saved ? "Saved to notebook" : "Save to notebook",
                  systemImage: saved ? "checkmark" : "tray.and.arrow.down")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(GlassButtonStyle())
        .disabled(!enabled)
    }
}
