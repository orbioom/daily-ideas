import SwiftUI

/// First-run onboarding, gated by the persisted `hasOnboarded` flag.
struct OnboardingView: View {
    @AppStorage(Prefs.hasOnboarded) private var hasOnboarded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    private struct Slide: Identifiable {
        let id = Int.random(in: 0...Int.max)
        let symbol: String
        let title: String
        let body: String
    }

    private let slides: [Slide] = [
        Slide(symbol: "text.book.closed.fill",
              title: "Conjugation, finally cracked",
              body: "Verbo drills the skill apps skip: putting verbs in the right form. A real engine generates every answer — yo · presente · hablar → hablo."),
        Slide(symbol: "brain.head.profile",
              title: "Adaptive, mastery-weighted drills",
              body: "Verbo tracks every verb and tense and quizzes you on your weak spots more often, so practice goes where it counts."),
        Slide(symbol: "tablecells",
              title: "Full reference tables",
              body: "Browse 60+ verbs with complete conjugation tables and clear tense explanations — your offline grammar companion."),
        Slide(symbol: "lock.open.fill",
              title: "One-time, offline, no account",
              body: "Spanish core is free forever. Unlock French and advanced tenses once — no subscription, no sign-in, no tracking."),
    ]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack {
                TabView(selection: $page) {
                    ForEach(Array(slides.enumerated()), id: \.offset) { index, slide in
                        VStack(spacing: 22) {
                            Spacer()
                            Image(systemName: slide.symbol)
                                .font(.system(size: 72))
                                .foregroundStyle(Theme.accent)
                                .accessibilityHidden(true)
                            Text(slide.title)
                                .font(Theme.serif(28, .bold))
                                .foregroundStyle(Theme.ink)
                                .multilineTextAlignment(.center)
                            Text(slide.body)
                                .font(Theme.rounded(16))
                                .foregroundStyle(Theme.inkSoft)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.horizontal, 8)
                            Spacer()
                        }
                        .padding(.horizontal, 28)
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .animation(reduceMotion ? nil : .easeInOut, value: page)

                VStack(spacing: 12) {
                    PrimaryButton(title: page == slides.count - 1 ? "Start learning" : "Continue") {
                        if page == slides.count - 1 {
                            hasOnboarded = true
                        } else {
                            page += 1
                        }
                    }
                    Button("Skip") { hasOnboarded = true }
                        .font(Theme.rounded(14, .medium))
                        .foregroundStyle(Theme.inkSoft)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 24)
            }
        }
    }
}
