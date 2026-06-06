import SwiftUI

/// A calm, single-screen first-run experience. Shown once, gated by a persisted flag.
struct OnboardingView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    private let points: [(icon: String, title: String, body: String)] = [
        ("camera.aperture", "Reason about exposure",
         "Pick any two of aperture, shutter, and ISO. Apertura solves the third with real photometry — EV = log2(N²/t)."),
        ("slider.horizontal.3", "See the trade-offs",
         "Depth of field, motion-blur risk, and grain shift as you dial. Honest guidance, clearly labelled — not a light meter."),
        ("film", "Keep a real logbook",
         "Build rolls of frames — stock, ISO, camera, the settings you chose — with the EV computed for you. Export any roll.")
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer(minLength: 24)

                VStack(spacing: 10) {
                    Image(systemName: "camera.aperture")
                        .font(.system(size: 52, weight: .light))
                        .foregroundStyle(Brand.text)
                        .accessibilityHidden(true)
                    Text("Apertura")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(Brand.text)
                    Text("A companion for manual & film photography.")
                        .font(.headline.weight(.regular))
                        .foregroundStyle(Brand.text2)
                        .multilineTextAlignment(.center)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)

                Spacer(minLength: 28)

                VStack(spacing: 14) {
                    ForEach(Array(points.enumerated()), id: \.offset) { idx, point in
                        GlassCard {
                            HStack(spacing: 14) {
                                Image(systemName: point.icon)
                                    .font(.title2)
                                    .foregroundStyle(Brand.text)
                                    .frame(width: 34)
                                    .accessibilityHidden(true)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(point.title)
                                        .font(.headline)
                                        .foregroundStyle(Brand.text)
                                    Text(point.body)
                                        .font(.subheadline)
                                        .foregroundStyle(Brand.text2)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer(minLength: 0)
                            }
                        }
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 16)
                        .animation(reduceMotion ? nil : Brand.ease(0.5).delay(0.08 * Double(idx + 1)),
                                   value: appeared)
                    }
                }
                .padding(.horizontal, 20)

                Spacer(minLength: 28)

                InkButton(title: "Start shooting", systemImage: "arrow.right") {
                    settings.hasOnboarded = true
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                .accessibilityHint("Dismisses this introduction and opens the calculator")
            }
            .frame(maxWidth: .infinity)
        }
        .onAppear {
            if reduceMotion { appeared = true }
            else { withAnimation(Brand.ease(0.6)) { appeared = true } }
        }
    }
}

#Preview {
    OnboardingView()
        .environment(SettingsStore())
        .background(Brand.pageBackground)
}
