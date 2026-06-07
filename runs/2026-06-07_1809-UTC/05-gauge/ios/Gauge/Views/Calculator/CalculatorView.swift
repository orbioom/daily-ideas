import SwiftUI

/// A standalone single-string tension calculator with two modes:
///  • Forward: scale + gauge + material + note → tension (lb & kg).
///  • Reverse: target tension + note + material + scale → suggested gauge.
struct CalculatorView: View {
    enum Mode: String, CaseIterable, Identifiable {
        case forward = "Tension"
        case reverse = "Find gauge"
        var id: String { rawValue }
    }

    @AppStorage("gauge.unit") private var unitRaw = WeightUnit.pounds.rawValue
    @State private var mode: Mode = .forward

    // Forward inputs.
    @State private var scaleText = "25.5"
    @State private var gauge = 10
    @State private var material: Material = .plainSteel
    @State private var note = "E4"

    // Reverse inputs.
    @State private var targetText = "18"
    @State private var targetUnitIsKg = false

    private var unit: WeightUnit { WeightUnit(rawValue: unitRaw) ?? .pounds }

    private var scale: Double? {
        Double(scaleText.replacingOccurrences(of: ",", with: "."))
    }
    private var scaleValid: Bool { (scale ?? 0) > 0 }
    private var noteValid: Bool { TensionEngine.frequency(for: note) != nil }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    VStack(spacing: 16) {
                        Picker("Mode", selection: $mode) {
                            ForEach(Mode.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: mode) { _, _ in Haptics.selection() }

                        if mode == .forward { forwardResult } else { reverseResult }

                        sharedInputs

                        if mode == .reverse { reverseInputs } else { gaugeInput }

                        glossaryHint
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Calculator")
        }
    }

    // MARK: - Result cards

    private var forwardTension: Double? {
        guard let scale, scale > 0 else { return nil }
        return TensionEngine.tensionLb(scaleLengthIn: scale,
                                       material: material,
                                       gaugeThou: gauge,
                                       noteName: note)
    }

    private var forwardResult: some View {
        GlassCard {
            VStack(spacing: 8) {
                Eyebrow(text: "String tension")
                if let t = forwardTension, t.isFinite {
                    Text(String(format: "%.2f lb", t))
                        .font(Brand.mono(36, weight: .bold))
                        .foregroundStyle(Brand.text)
                    Text(String(format: "%.2f kg", t * TensionEngine.lbToKg))
                        .font(Brand.mono(18, weight: .medium))
                        .foregroundStyle(Brand.text2)
                    Badge(text: TensionEngine.comfort(tensionLb: t, isBass: false).label,
                          color: TensionEngine.comfort(tensionLb: t, isBass: false).color)
                } else {
                    Text("—")
                        .font(Brand.mono(36, weight: .bold))
                        .foregroundStyle(Brand.danger)
                    Text(invalidMessage)
                        .font(.caption)
                        .foregroundStyle(Brand.text2)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)
        }
    }

    private var targetLb: Double? {
        guard let raw = Double(targetText.replacingOccurrences(of: ",", with: ".")), raw > 0 else { return nil }
        return targetUnitIsKg ? raw / TensionEngine.lbToKg : raw
    }

    private var suggestedGauge: Int? {
        guard let scale, scale > 0, let target = targetLb else { return nil }
        return TensionEngine.suggestedGauge(targetLb: target,
                                            scaleLengthIn: scale,
                                            material: material,
                                            noteName: note)
    }

    private var reverseResult: some View {
        GlassCard {
            VStack(spacing: 8) {
                Eyebrow(text: "Suggested gauge")
                if let g = suggestedGauge {
                    Text(String(format: ".%03d\"", g))
                        .font(Brand.mono(36, weight: .bold))
                        .foregroundStyle(Brand.text)
                    if let achieved = achievedTension(forGauge: g) {
                        Text(String(format: "≈ %.2f lb  ·  %.2f kg",
                                    achieved, achieved * TensionEngine.lbToKg))
                            .font(Brand.mono(14, weight: .medium))
                            .foregroundStyle(Brand.text2)
                    }
                } else {
                    Text("—")
                        .font(Brand.mono(36, weight: .bold))
                        .foregroundStyle(Brand.danger)
                    Text(invalidMessage)
                        .font(.caption)
                        .foregroundStyle(Brand.text2)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)
        }
    }

    private func achievedTension(forGauge g: Int) -> Double? {
        guard let scale, scale > 0 else { return nil }
        let t = TensionEngine.tensionLb(scaleLengthIn: scale,
                                        material: material,
                                        gaugeThou: g,
                                        noteName: note)
        guard let t, t.isFinite else { return nil }
        return t
    }

    // MARK: - Inputs

    private var sharedInputs: some View {
        VStack(spacing: 16) {
            GlassCard {
                VStack(alignment: .leading, spacing: 10) {
                    SectionTitle(text: "Scale length (inches)")
                    TextField("25.5", text: $scaleText)
                        .keyboardType(.decimalPad)
                        .font(Brand.mono(17, weight: .medium))
                    if !scaleValid {
                        Label("Enter a scale length above zero.", systemImage: "exclamationmark.triangle")
                            .font(.caption).foregroundStyle(Brand.warn)
                    }
                }
            }
            GlassCard {
                VStack(alignment: .leading, spacing: 10) {
                    SectionTitle(text: "Note")
                    TextField("E4", text: $note)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .font(Brand.mono(17, weight: .medium))
                    if noteValid, let f = TensionEngine.frequency(for: note) {
                        Text(String(format: "%.2f Hz", f))
                            .font(Brand.mono(12)).foregroundStyle(Brand.text3)
                    } else {
                        Label("Use a letter A–G, optional # or b, and an octave.", systemImage: "exclamationmark.triangle")
                            .font(.caption).foregroundStyle(Brand.warn)
                    }
                }
            }
            GlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    SectionTitle(text: "Material")
                    Picker("Material", selection: $material) {
                        ForEach(Material.allCases) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.navigationLink)
                }
            }
        }
    }

    private var gaugeInput: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    SectionTitle(text: "Gauge")
                    Spacer()
                    Text(String(format: ".%03d\"", gauge))
                        .font(Brand.mono(17, weight: .semibold))
                        .foregroundStyle(Brand.text)
                }
                Stepper(value: gaugeBinding, in: 6...140, step: 1) {
                    Text("Gauge in thousandths of an inch")
                        .font(.subheadline).foregroundStyle(Brand.text2)
                }
            }
        }
    }

    private var reverseInputs: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionTitle(text: "Target tension")
                HStack {
                    TextField("18", text: $targetText)
                        .keyboardType(.decimalPad)
                        .font(Brand.mono(17, weight: .medium))
                    Picker("Unit", selection: $targetUnitIsKg) {
                        Text("lb").tag(false)
                        Text("kg").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 120)
                }
                if targetLb == nil {
                    Label("Enter a target tension above zero.", systemImage: "exclamationmark.triangle")
                        .font(.caption).foregroundStyle(Brand.warn)
                }
            }
        }
    }

    private var glossaryHint: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 6) {
                Eyebrow(text: "Tip")
                Text("Tension rises with the square of frequency and scale length, and linearly with the string's mass per inch. A .010 plain at E4 on a 25.5\" scale sits near 16 lb.")
                    .font(.caption)
                    .foregroundStyle(Brand.text2)
            }
        }
    }

    private var gaugeBinding: Binding<Int> {
        Binding(get: { gauge }, set: { gauge = min(max($0, 1), 200); Haptics.selection() })
    }

    private var invalidMessage: String {
        if !scaleValid { return "Enter a scale length above zero." }
        if !noteValid { return "That note can't be read." }
        if mode == .reverse && targetLb == nil { return "Enter a target tension above zero." }
        return "Check your inputs."
    }
}
