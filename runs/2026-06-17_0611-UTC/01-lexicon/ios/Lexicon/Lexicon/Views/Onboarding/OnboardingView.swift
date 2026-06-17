import SwiftUI

/// First-run onboarding, gated by the persisted `hasOnboarded` flag. Three calm
/// pages, then "Start playing" flips the flag and reveals the main experience.
struct OnboardingView: View {
    @Environment(\.colorScheme) private var scheme
    @AppStorage(PrefKey.hasOnboarded) private var hasOnboarded: Bool = false
    @State private var page = 0

    private struct Page: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let body: String
    }

    private let pages: [Page] = [
        Page(icon: "square.grid.3x3.fill",
             title: "A word a day",
             body: "Guess the hidden word in six tries. Everyone gets the same daily puzzle — see how your streak grows."),
        Page(icon: "infinity",
             title: "Play as much as you like",
             body: "Unlimited practice rounds in 4, 5 and 6 letters, plus a full archive of past puzzles. No ads, fully offline."),
        Page(icon: "paintpalette.fill",
             title: "Made for everyone",
             body: "High-contrast colors, full VoiceOver and Dynamic Type, light and dark themes, and gentle haptics — all yours to tune.")
    ]

    var body: some View {
        ZStack {
            LexBackground()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, p in
                        pageView(p).tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))

                VStack(spacing: 12) {
                    Button(page == pages.count - 1 ? "Start playing" : "Next") {
                        advance()
                    }
                    .buttonStyle(LexPrimaryButtonStyle())

                    if page < pages.count - 1 {
                        Button("Skip") { finish() }
                            .font(.subheadline)
                            .foregroundStyle(LexTheme.secondaryText(scheme))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }

    private func pageView(_ p: Page) -> some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle().fill(LexTheme.green.opacity(0.14)).frame(width: 130, height: 130)
                Image(systemName: p.icon)
                    .font(.system(size: 56))
                    .foregroundStyle(LexTheme.green)
            }
            .accessibilityHidden(true)
            Text(p.title)
                .font(LexTheme.display(28, weight: .bold))
                .foregroundStyle(LexTheme.primaryText(scheme))
                .multilineTextAlignment(.center)
            Text(p.body)
                .font(.body)
                .foregroundStyle(LexTheme.secondaryText(scheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
        .padding()
        .accessibilityElement(children: .combine)
    }

    private func advance() {
        if page < pages.count - 1 {
            withAnimation { page += 1 }
        } else {
            finish()
        }
    }

    private func finish() {
        Haptics.light()
        hasOnboarded = true
    }
}
