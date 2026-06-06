import SwiftUI

/// A calm, single-screen first-run experience. Shown once, gated by a persisted flag.
struct OnboardingView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    private let points: [(icon: String, title: String, body: String)] = [
        ("music.note.list", "Build your repertoire",
         "Every piece you're working on, with the passages that actually need the hours."),
        ("metronome", "Practice with intent",
         "A metronome and countdown timer drive a session hands-free — and log it when you're done."),
        ("chart.bar.fill", "Watch progress accumulate",
         "Streaks, weekly minutes, time per piece, and what to play next — drawn from real sessions.")
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer(minLength: 24)

                VStack(spacing: 10) {
                    Image(systemName: "waveform")
                        .font(.system(size: 52, weight: .light))
                        .foregroundStyle(Brand.text)
                        .accessibilityHidden(true)
                    Text("Repertoire")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(Brand.text)
                    Text("Your practice, honestly recorded.")
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

                InkButton(title: "Start practicing", systemImage: "arrow.right") {
                    settings.hasOnboarded = true
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                .accessibilityHint("Dismisses this introduction and opens your repertoire")
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
