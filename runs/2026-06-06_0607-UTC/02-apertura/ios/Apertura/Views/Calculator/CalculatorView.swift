import SwiftUI

/// The exposure calculator / visualizer. Preloaded with a sensible, usable scene.
/// Pick which leg to solve, dial the other two, and watch EV, the target delta, the
/// trade-off guidance, and equivalent exposures update live.
struct CalculatorView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var model = CalculatorViewModel()
    @State private var didPrime = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    evCard
                    solveCard
                    legControls
                    guidanceCard
                    equivalentsCard
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle("Calculator")
            .onAppear(perform: prime)
        }
    }

    // MARK: - Priming

    /// Apply the user's default increment once; keep the preloaded daylight scene.
    private func prime() {
        guard !didPrime else { return }
        model.increment = settings.defaultIncrement
        model.iso = settings.defaultISO
        didPrime = true
    }

    // MARK: - EV + target card

    private var evCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .firstTextBaseline) {
                    MonoReadout(value: evText,
                                caption: "EV at ISO \(isoText)",
                                tint: Brand.text, size: 40)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(Exposure.apertureString(model.aperture))
                            .font(Brand.mono(20, weight: .semibold))
                            .foregroundStyle(Brand.aperture)
                        Text(Exposure.shutterString(model.shutterSeconds))
                            .font(Brand.mono(20, weight: .semibold))
                            .foregroundStyle(Brand.shutter)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Settings")
                    .accessibilityValue("\(Exposure.apertureString(model.aperture)), \(Exposure.shutterString(model.shutterSeconds))")
                }

                Divider().overlay(Brand.glassStroke.opacity(0.4))

                // Metered target + delta
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        SectionLabel(text: "Metered scene · EV100")
                        Spacer()
                        Text(Exposure.evString(model.targetEV100))
                            .font(Brand.mono(15, weight: .semibold))
                            .foregroundStyle(Brand.text2)
                    }
                    Slider(value: $model.targetEV100, in: -2...20, step: 0.5)
                        .tint(Brand.text)
                        .accessibilityLabel("Metered scene EV")
                        .accessibilityValue(Exposure.evString(model.targetEV100))

                    HStack(spacing: 8) {
                        Image(systemName: deltaIcon)
                            .foregroundStyle(deltaTint)
                            .accessibilityHidden(true)
                        Text(deltaText)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(deltaTint)
                        Spacer()
                        Button {
                            model.captureCurrentAsTarget()
                            Haptics.impact(enabled: settings.hapticsEnabled)
                        } label: {
                            Text("Meter from current")
                                .font(.caption.weight(.semibold))
                        }
                        .tint(Brand.text)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Exposure relative to target: \(deltaText)")
                }
            }
        }
    }

    private var evText: String {
        model.currentEV.map { Exposure.evString($0) } ?? "—"
    }
    private var isoText: String { String(format: "%.0f", model.iso) }

    private var deltaText: String {
        guard let stops = model.stopsFromTarget else { return "—" }
        return Exposure.stopsDescription(stops)
    }
    private var deltaTint: Color {
        guard let stops = model.stopsFromTarget else { return Brand.text3 }
        return abs(stops) < 0.2 ? Brand.live : Brand.warm
    }
    private var deltaIcon: String {
        guard let stops = model.stopsFromTarget else { return "questionmark.circle" }
        if abs(stops) < 0.2 { return "checkmark.circle.fill" }
        return stops > 0 ? "moon.fill" : "sun.max.fill"
    }

    // MARK: - Solve card

    private var solveCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionLabel(text: "Solve for")
                Picker("Solve for", selection: $model.solveTarget) {
                    ForEach(SolveTarget.allCases) { t in
                        Text(t.title).tag(t)
                    }
                }
                .pickerStyle(.segmented)

                HStack {
                    SectionLabel(text: "Increment")
                    Spacer()
                    Picker("Increment", selection: $model.increment) {
                        ForEach(StopIncrement.allCases) { inc in
                            Text(inc.title).tag(inc)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                }

                InkButton(title: "Solve \(model.solveTarget.title.lowercased()) for target",
                          systemImage: "function") {
                    withAnimation(reduceMotion ? nil : Brand.ease()) {
                        model.solveSelectedLeg()
                    }
                    Haptics.success(enabled: settings.hapticsEnabled)
                }
            }
        }
    }

    // MARK: - Leg controls (the two dialled legs + focal)

    private var legControls: some View {
        GlassCard {
            VStack(spacing: 18) {
                if model.solveTarget != .aperture {
                    apertureControl
                }
                if model.solveTarget != .shutter {
                    shutterControl
                }
                if model.solveTarget != .iso {
                    isoControl
                }
                focalControl
            }
        }
    }

    private var apertureControl: some View {
        StopSliderRow(
            title: "Aperture",
            valueLabel: Exposure.apertureString(model.aperture),
            tint: Brand.aperture,
            systemImage: "camera.aperture",
            value: Binding(
                get: { 2.0 * log2(max(model.aperture, 0.5)) },     // stops from f/1
                set: { model.aperture = pow(2.0, $0 / 2.0) }
            ),
            range: 0...12,                                          // f/1 .. f/64
            step: model.increment.stepInStops,
            accessibilityValue: Exposure.apertureString(model.aperture)
        )
        .onChange(of: model.increment) { _, _ in snap() }
    }

    private var shutterControl: some View {
        StopSliderRow(
            title: "Shutter",
            valueLabel: Exposure.shutterString(model.shutterSeconds),
            tint: Brand.shutter,
            systemImage: "timer",
            value: Binding(
                get: { -log2(max(model.shutterSeconds, 1.0/16000)) }, // stops from 1s
                set: { model.shutterSeconds = pow(2.0, -$0) }
            ),
            range: -5...13,                                            // 30s .. 1/8000
            step: model.increment.stepInStops,
            accessibilityValue: Exposure.shutterString(model.shutterSeconds)
        )
    }

    private var isoControl: some View {
        StopSliderRow(
            title: "ISO",
            valueLabel: String(format: "%.0f", model.iso),
            tint: Brand.iso,
            systemImage: "circle.dotted",
            value: Binding(
                get: { log2(max(model.iso, 25) / 100.0) },           // stops from ISO 100
                set: { model.iso = 100.0 * pow(2.0, $0) }
            ),
            range: -2...8,                                            // ISO 25 .. 25600
            step: model.increment.stepInStops,
            accessibilityValue: "ISO \(Int(model.iso.rounded()))"
        )
    }

    private var focalControl: some View {
        StopSliderRow(
            title: "Focal length",
            valueLabel: "\(Int(model.focalLengthMM.rounded())) mm",
            tint: Brand.text2,
            systemImage: "scope",
            value: $model.focalLengthMM,
            range: 12...300,
            step: 1,
            accessibilityValue: "\(Int(model.focalLengthMM.rounded())) millimetres"
        )
    }

    private func snap() {
        model.snapInputs()
    }

    // MARK: - Guidance card

    private var guidanceCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    SectionLabel(text: "Trade-off guidance")
                    Spacer()
                    Text("guidance, not a meter")
                        .font(.caption2)
                        .foregroundStyle(Brand.text3)
                        .italic()
                }
                HStack(spacing: 10) {
                    GuidancePill(title: "Depth of field", level: model.depthOfField,
                                 systemImage: "square.3.layers.3d")
                    GuidancePill(title: "Motion blur", level: model.motionBlur,
                                 systemImage: "wind")
                    GuidancePill(title: "Grain / noise", level: model.noiseLevel,
                                 systemImage: "circle.grid.3x3")
                }
                Text(guidanceNote)
                    .font(.caption)
                    .foregroundStyle(Brand.text2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var guidanceNote: String {
        switch model.depthOfField {
        case .high:
            return "Wide aperture and/or long lens: a shallow plane of focus — backgrounds melt away."
        case .medium:
            return "A moderate depth of field — your subject sits clearly against a soft surround."
        case .low:
            return "Stopped down: deep focus, front to back. Great for landscapes; watch your shutter."
        }
    }

    // MARK: - Equivalents card

    private var equivalentsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    SectionLabel(text: "Equivalent exposures")
                    Spacer()
                    Text("same EV · \(model.increment.symbol) stops")
                        .font(.caption2)
                        .foregroundStyle(Brand.text3)
                }
                let pairs = model.equivalents
                if pairs.isEmpty {
                    Text("Dial a valid exposure to see equivalent aperture and shutter pairs.")
                        .font(.subheadline)
                        .foregroundStyle(Brand.text2)
                } else {
                    VStack(spacing: 0) {
                        ForEach(pairs) { pair in
                            HStack {
                                Text(Exposure.apertureString(pair.aperture))
                                    .font(Brand.mono(16, weight: .medium))
                                    .foregroundStyle(Brand.aperture)
                                    .frame(width: 80, alignment: .leading)
                                Image(systemName: "arrow.left.arrow.right")
                                    .font(.caption)
                                    .foregroundStyle(Brand.text3)
                                    .accessibilityHidden(true)
                                Spacer()
                                Text(Exposure.shutterString(pair.shutterSeconds))
                                    .font(Brand.mono(16, weight: .medium))
                                    .foregroundStyle(Brand.shutter)
                            }
                            .padding(.vertical, 9)
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel("\(Exposure.apertureString(pair.aperture)) at \(Exposure.shutterString(pair.shutterSeconds))")
                            if pair.id != pairs.last?.id {
                                Divider().overlay(Brand.glassStroke.opacity(0.3))
                            }
                        }
                    }
                }
            }
        }
    }
}

/// A labelled slider row that snaps to stop increments and exposes a VoiceOver value.
private struct StopSliderRow: View {
    var title: String
    var valueLabel: String
    var tint: Color
    var systemImage: String
    @Binding var value: Double
    var range: ClosedRange<Double>
    var step: Double
    var accessibilityValue: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(title, systemImage: systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Brand.text2)
                    .labelStyle(.titleAndIcon)
                Spacer()
                Text(valueLabel)
                    .font(Brand.mono(16, weight: .semibold))
                    .foregroundStyle(tint)
            }
            Slider(value: $value, in: range, step: step > 0 ? step : 0.01)
                .tint(tint)
                .accessibilityLabel(title)
                .accessibilityValue(accessibilityValue)
        }
    }
}

#Preview {
    CalculatorView()
        .environment(SettingsStore())
}
