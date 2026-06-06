import SwiftUI

/// A calm, single-screen first-run experience. Shown once, gated by a persisted flag.
struct OnboardingView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    private let points: [(icon: String, title: String, body: String)] = [
        ("list.bullet.rectangle", "Log every session",
         "Record attempts in order — flash, send, repeat, or fall — at the gym or the crag."),
        ("arrow.left.arrow.right", "Grades, your way",
         "Strata converts between V-scale & Font, YDS & French. Pick your preferred system; it converts on display."),
        ("chart.bar.xaxis", "Watch yourself progress",
         "A live send pyramid, flash rate, and month-by-month progression — built from your real attempts.")
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer(minLength: 24)

                VStack(spacing: 10) {
                    Image(systemName: "mountain.2.fill")
                        .font(.system(size: 52, weight: .light))
                        .foregroundStyle(Brand.text)
                        .accessibilityHidden(true)
                    Text("Strata")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(Brand.text)
                    Text("Your climbing logbook, layer by layer.")
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

                InkButton(title: "Start climbing", systemImage: "arrow.right") {
                    settings.hasOnboarded = true
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                .accessibilityHint("Dismisses this introduction and opens your sessions")
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
}
