import SwiftUI

/// First-run onboarding, gated by the persisted `hasOnboarded` flag.
struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded: Bool = false
    @Environment(\.colorScheme) private var scheme
    @State private var page = 0

    private struct Slide: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let body: String
    }

    private let slides: [Slide] = [
        Slide(icon: "tuningfork",
              title: "Tune by ear, perfected",
              body: "Pitch listens through your mic and uses on-device pitch detection to tune any instrument with studio precision."),
        Slide(icon: "metronome.fill",
              title: "A metronome that never drifts",
              body: "Sample-accurate clicks, tap tempo, accents, and subdivisions — all synthesized on device."),
        Slide(icon: "tuningfork",
              title: "Reference tones on demand",
              body: "Need a pitch pipe? Play a sustained reference tone for any note, with a tunable A4."),
        Slide(icon: "lock.open",
              title: "No ads. Yours to own.",
              body: "The tuner, metronome, and tones are free. A one-time Pro unlock adds custom tunings and advanced tools.")
    ]

    var body: some View {
        ZStack {
            PitchTheme.appBackground(scheme).ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(slides.enumerated()), id: \.element.id) { index, slide in
                        slideView(slide)
                            .tag(index)
                            .padding(.horizontal, 28)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))

                VStack(spacing: 12) {
                    Button(page < slides.count - 1 ? "Continue" : "Start tuning") {
                        if page < slides.count - 1 {
                            withAnimation { page += 1 }
                        } else {
                            hasOnboarded = true
                        }
                    }
                    .buttonStyle(PitchPrimaryButtonStyle())

                    if page < slides.count - 1 {
                        Button("Skip") { hasOnboarded = true }
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(PitchTheme.secondaryText(scheme))
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 24)
            }
        }
    }

    private func slideView(_ slide: Slide) -> some View {
        VStack(spacing: 22) {
            Spacer(minLength: 0)
            ZStack {
                Circle()
                    .fill(PitchTheme.indigo.opacity(0.16))
                    .frame(width: 132, height: 132)
                Image(systemName: slide.icon)
                    .font(.system(size: 56, weight: .bold))
                    .foregroundStyle(PitchTheme.indigo)
            }
            .accessibilityHidden(true)
            VStack(spacing: 12) {
                Text(slide.title)
                    .font(PitchTheme.display(28))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(PitchTheme.primaryText(scheme))
                Text(slide.body)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(PitchTheme.secondaryText(scheme))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}
