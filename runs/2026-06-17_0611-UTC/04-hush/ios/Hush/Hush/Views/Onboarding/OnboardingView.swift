import SwiftUI

/// First-run onboarding. Three concise pages explaining the value, then a
/// "Get started" button that flips the persisted `hasOnboarded` flag.
struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded: Bool = false
    @Environment(\.colorScheme) private var scheme
    @Environment(AppSettings.self) private var settings
    @State private var page = 0

    private let pages: [OnboardPage] = [
        OnboardPage(icon: "waveform",
                    title: "Sounds, synthesized live",
                    body: "Every sound in Hush is generated on your device in real time — no downloads, no streaming. The app is tiny and works fully offline, even in airplane mode."),
        OnboardPage(icon: "square.stack.3d.up.fill",
                    title: "Layer your perfect night",
                    body: "Blend rain, ocean, wind, a fan and more. Tune each layer's volume, save your favorite mixes, and load them with a tap."),
        OnboardPage(icon: "moon.zzz.fill",
                    title: "Drift off, gently",
                    body: "Set a sleep timer that slowly fades to silence and keeps playing in the background. One-time purchase — no subscriptions, ever.")
    ]

    var body: some View {
        ZStack {
            HushTheme.appBackground(scheme).ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { idx, p in
                        OnboardPageView(page: p).tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))

                VStack(spacing: 12) {
                    Button(page == pages.count - 1 ? "Get started" : "Next") {
                        Haptics.tap(settings.hapticsEnabled)
                        if page == pages.count - 1 {
                            hasOnboarded = true
                        } else {
                            withAnimation { page += 1 }
                        }
                    }
                    .buttonStyle(HushPrimaryButtonStyle())

                    Button("Skip") {
                        hasOnboarded = true
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(HushTheme.secondaryText(scheme))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }
}

private struct OnboardPage: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let body: String
}

private struct OnboardPageView: View {
    @Environment(\.colorScheme) private var scheme
    let page: OnboardPage

    var body: some View {
        VStack(spacing: 22) {
            Spacer()
            ZStack {
                Circle()
                    .fill(HushTheme.teal.opacity(0.14))
                    .frame(width: 140, height: 140)
                Image(systemName: page.icon)
                    .font(.system(size: 60, weight: .semibold))
                    .foregroundStyle(HushTheme.teal)
            }
            .accessibilityHidden(true)

            Text(page.title)
                .font(.title.weight(.bold))
                .foregroundStyle(HushTheme.primaryText(scheme))
                .multilineTextAlignment(.center)

            Text(page.body)
                .font(.body)
                .foregroundStyle(HushTheme.secondaryText(scheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
            Spacer()
        }
        .padding()
        .accessibilityElement(children: .combine)
    }
}
