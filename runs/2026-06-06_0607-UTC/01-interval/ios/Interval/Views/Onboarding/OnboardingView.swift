import SwiftUI

/// A calm, single-screen first-run experience. Shown once, gated by `hasLaunchedBefore`.
struct OnboardingView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    private let points: [(icon: String, title: String, body: String)] = [
        ("square.stack.3d.up.fill", "Build a routine once",
         "Warm-up, rounds of work and rest, cooldown — assembled from segments you can reorder."),
        ("repeat", "Repeat groups, expanded for you",
         "Wrap segments in a group and run it eight times. Interval flattens it into a precise timeline."),
        ("timer", "Run it hands-free",
         "A full-screen countdown with the next step queued, haptic cues, and a screen that stays awake.")
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer(minLength: 24)

                VStack(spacing: 10) {
                    RingGlyph(progress: 0.7, lineWidth: 8)
                        .frame(width: 72, height: 72)
                        .accessibilityHidden(true)
                    Text("Interval")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(Brand.text)
                    Text("Interval timers, calmly built and run.")
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

                InkButton(title: "Start building", systemImage: "arrow.right") {
                    settings.hasLaunchedBefore = true
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                .accessibilityHint("Dismisses this introduction and opens your routines")
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
    ZStack {
        Brand.pageBackground
        OnboardingView()
            .environment(SettingsStore(defaults: UserDefaults(suiteName: "preview") ?? .standard))
    }
}
