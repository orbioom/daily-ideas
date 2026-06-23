import SwiftUI

/// First-run onboarding. Three pages explaining the value, then a CTA that
/// flips the persisted `hasOnboarded` flag via the `onFinish` closure.
struct OnboardingView: View {
    var onFinish: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    private let pages: [OnboardPage] = [
        OnboardPage(
            symbol: "globe.europe.africa.fill",
            title: "Phrases that travel with you",
            body: "Curated survival decks for Spanish, French, Italian and Japanese — over 200 real travel phrases, fully offline."
        ),
        OnboardPage(
            symbol: "brain.head.profile",
            title: "Remember them for the trip",
            body: "A proven SM-2 spaced-repetition scheduler shows each phrase right before you'd forget it — no grinding, just review."
        ),
        OnboardPage(
            symbol: "speaker.wave.3.fill",
            title: "Hear every word",
            body: "Tap to hear native-style pronunciation on-device. Practice in the airport, the metro, or with no signal at all."
        )
    ]

    var body: some View {
        ZStack {
            Theme.brandGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, item in
                        OnboardPageView(page: item, reduceMotion: reduceMotion)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                pageDots
                    .padding(.bottom, Theme.Spacing.lg)

                controls
                    .padding(.horizontal, Theme.Spacing.xl)
                    .padding(.bottom, Theme.Spacing.xl)
            }
        }
    }

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(pages.indices, id: \.self) { i in
                Capsule()
                    .fill(.white.opacity(i == page ? 1 : 0.4))
                    .frame(width: i == page ? 22 : 8, height: 8)
                    .animation(reduceMotion ? nil : .spring(response: 0.3), value: page)
            }
        }
        .accessibilityHidden(true)
    }

    private var controls: some View {
        VStack(spacing: Theme.Spacing.md) {
            Button {
                if page < pages.count - 1 {
                    withAnimation { page += 1 }
                } else {
                    onFinish()
                }
            } label: {
                Text(page < pages.count - 1 ? "Continue" : "Start exploring")
                    .font(.headline)
                    .foregroundStyle(Theme.brand)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.md + 2)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                            .fill(.white)
                    )
            }
            .accessibilityHint(page < pages.count - 1 ? "Goes to the next page" : "Opens the app")

            Button("Skip") { onFinish() }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.9))
                .opacity(page < pages.count - 1 ? 1 : 0)
                .disabled(page == pages.count - 1)
                .accessibilityHidden(page == pages.count - 1)
        }
    }
}

private struct OnboardPage: Identifiable {
    let id = UUID()
    let symbol: String
    let title: String
    let body: String
}

private struct OnboardPageView: View {
    let page: OnboardPage
    let reduceMotion: Bool
    @State private var appeared = false

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()
            Image(systemName: page.symbol)
                .font(.system(size: 92, weight: .semibold))
                .foregroundStyle(.white)
                .scaleEffect(appeared || reduceMotion ? 1 : 0.6)
                .opacity(appeared || reduceMotion ? 1 : 0)
                .accessibilityHidden(true)
            VStack(spacing: Theme.Spacing.md) {
                Text(page.title)
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                Text(page.body)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.92))
            }
            .padding(.horizontal, Theme.Spacing.xl)
            Spacer()
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .onAppear {
            guard !reduceMotion else { appeared = true; return }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { appeared = true }
        }
    }
}

#Preview {
    OnboardingView(onFinish: {})
}
