import SwiftUI

/// Three-page first-run onboarding, gated by a persisted flag.
struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var page = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            symbol: "wand.and.stars",
            title: "Lists that pack themselves",
            message: "Tell Packwise where you're going and it builds a tailored checklist in seconds — scaled to your nights, travelers and activities."
        ),
        OnboardingPage(
            symbol: "checklist",
            title: "Tick it off, stress-free",
            message: "Check items as you pack and watch your progress ring fill. Add your own items and never forget the charger again."
        ),
        OnboardingPage(
            symbol: "square.stack.3d.up.fill",
            title: "Save & reuse templates",
            message: "Turn your perfect carry-on into a reusable template, and juggle several trips at once without mixing them up."
        )
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Theme.primary, Theme.primary.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, item in
                        VStack(spacing: Theme.Space.xl) {
                            Image(systemName: item.symbol)
                                .font(.system(size: 92, weight: .regular))
                                .foregroundStyle(.white)
                                .accessibilityHidden(true)
                                .padding(.bottom, Theme.Space.sm)
                            Text(item.title)
                                .font(.largeTitle.weight(.bold))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                            Text(item.message)
                                .font(.body)
                                .foregroundStyle(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, Theme.Space.xl)
                        }
                        .padding()
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .animation(reduceMotion ? nil : .easeInOut, value: page)

                VStack(spacing: Theme.Space.md) {
                    Button {
                        advance()
                    } label: {
                        Text(page == pages.count - 1 ? "Start packing" : "Next")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.Space.md)
                            .background(.white)
                            .foregroundStyle(Theme.primary)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.chip, style: .continuous))
                    }
                    .accessibilityHint(page == pages.count - 1 ? "Finishes setup and opens the app" : "Goes to the next page")

                    Button("Skip") {
                        finish()
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .opacity(page == pages.count - 1 ? 0 : 1)
                    .disabled(page == pages.count - 1)
                }
                .padding(.horizontal, Theme.Space.xl)
                .padding(.bottom, Theme.Space.xl)
            }
        }
    }

    private func advance() {
        if page < pages.count - 1 {
            withAnimation(reduceMotion ? nil : .easeInOut) { page += 1 }
        } else {
            finish()
        }
    }

    private func finish() {
        hasCompletedOnboarding = true
    }
}

private struct OnboardingPage {
    let symbol: String
    let title: String
    let message: String
}
