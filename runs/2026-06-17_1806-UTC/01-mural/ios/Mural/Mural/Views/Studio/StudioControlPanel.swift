import SwiftUI

/// The control surface for the studio. Only the controls relevant to the chosen style appear.
struct StudioControlPanel: View {
    @Binding var spec: WallpaperSpec
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Controls")
                .font(Theme.rounded(14, .semibold))
                .foregroundStyle(Theme.inkSoft)

            if spec.style.usesQuote {
                quoteControls
            }

            if spec.style.usesAngle {
                LabeledSlider(
                    title: "Direction",
                    value: $spec.angle,
                    range: 0...360,
                    systemImage: "angle"
                )
            }

            if spec.style.usesComplexity {
                complexityControl
            }

            LabeledSlider(title: "Grain", value: $spec.grain, range: 0...1, systemImage: "circle.dotted")
            LabeledSlider(title: "Vignette", value: $spec.vignette, range: 0...1, systemImage: "circle.lefthalf.filled")
            LabeledSlider(title: "Softness", value: $spec.blur, range: 0...1, systemImage: "aqi.medium")

            seedRow
        }
        .padding(18)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous).strokeBorder(Theme.hairline, lineWidth: 1))
    }

    private var quoteControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Quote text", systemImage: "text.quote")
                .font(Theme.rounded(14, .medium))
                .foregroundStyle(Theme.inkSoft)
            TextField("Type a few words…", text: Binding(
                get: { spec.quoteText ?? "" },
                set: { spec.quoteText = $0 }
            ), axis: .vertical)
            .font(Theme.rounded(16))
            .lineLimit(1...3)
            .padding(12)
            .background(Theme.surfaceRaised, in: RoundedRectangle(cornerRadius: Theme.radiusSmall, style: .continuous))
            .accessibilityLabel("Wallpaper quote text")

            HStack {
                Label("Weight", systemImage: "bold")
                    .font(Theme.rounded(14, .medium))
                    .foregroundStyle(Theme.inkSoft)
                Spacer()
                Picker("Weight", selection: $spec.quoteWeightRaw) {
                    Text("Light").tag(0)
                    Text("Regular").tag(1)
                    Text("Medium").tag(2)
                    Text("Semibold").tag(3)
                    Text("Bold").tag(4)
                }
                .pickerStyle(.menu)
                .tint(Theme.accent)
            }
        }
    }

    private var complexityControl: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label("Complexity", systemImage: "square.grid.3x3.fill")
                    .font(Theme.rounded(14, .medium))
                    .foregroundStyle(Theme.inkSoft)
                Spacer()
                Text("\(spec.complexity)")
                    .font(Theme.rounded(13, .semibold).monospacedDigit())
                    .foregroundStyle(Theme.inkFaint)
            }
            Slider(
                value: Binding(
                    get: { Double(spec.complexity) },
                    set: { spec.complexity = Int($0.rounded()) }
                ),
                in: 2...20,
                step: 1
            )
            .tint(Theme.accent)
            .accessibilityValue("\(spec.complexity)")
        }
    }

    private var seedRow: some View {
        HStack {
            Label("Seed", systemImage: "number")
                .font(Theme.rounded(14, .medium))
                .foregroundStyle(Theme.inkSoft)
            Spacer()
            Text(String(spec.seed % 1_000_000))
                .font(Theme.rounded(13, .semibold).monospacedDigit())
                .foregroundStyle(Theme.inkFaint)
            Button {
                Haptics.impact(.light, enabled: settings.hapticsEnabled)
                var rng = SplitMix64(seed: spec.seed &+ 0x1234)
                spec.seed = rng.next()
            } label: {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.accent)
            }
            .accessibilityLabel("Reseed")
            .accessibilityHint("Generates a new random variation")
        }
    }
}
