import SwiftUI

/// First-run introduction. Gated by @AppStorage("hasOnboarded"); sets it true on finish.
struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("preferredTier") private var preferredTier = WordTier.everyday.rawValue
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    private let pages: [OnboardPage] = [
        OnboardPage(icon: "book", title: "Welcome to Lexeme",
                    body: "A calm, ad-free way to build a richer English vocabulary — for the SAT, the GRE, or the pure love of words."),
        OnboardPage(icon: "sun.max", title: "A word a day",
                    body: "Each morning brings one carefully chosen word: its meaning, an example in a real sentence, and where it came from."),
        OnboardPage(icon: "brain.head.profile", title: "Remember it for good",
                    body: "Smart spaced repetition resurfaces words right before you'd forget them — so they actually stick."),
    ]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { i in
                        pageView(pages[i]).tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(reduceMotion ? nil : .easeInOut, value: page)

                indicators
                    .padding(.bottom, 8)

                if page == pages.count - 1 {
                    tierPicker
                        .padding(.horizontal, 28)
                        .padding(.bottom, 8)
                }

                PrimaryButton(title: page == pages.count - 1 ? "Begin" : "Next",
                              systemImage: page == pages.count - 1 ? "arrow.right" : nil) {
                    Haptics.tap()
                    if page < pages.count - 1 {
                        withAnimation(reduceMotion ? nil : .easeInOut) { page += 1 }
                    } else {
                        hasOnboarded = true
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 18)

                Button("Skip") {
                    Haptics.tap()
                    hasOnboarded = true
                }
                .font(Theme.rounded(14))
                .foregroundStyle(Theme.inkFaint)
                .padding(.bottom, 12)
            }
        }
    }

    private func pageView(_ p: OnboardPage) -> some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle().fill(Theme.accentSoft).frame(width: 140, height: 140)
                Image(systemName: p.icon)
                    .font(.system(size: 58, weight: .light))
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
            }
            VStack(spacing: 12) {
                Text(p.title)
                    .font(Theme.serif(28, .bold))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                Text(p.body)
                    .font(Theme.rounded(16))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }

    private var indicators: some View {
        HStack(spacing: 8) {
            ForEach(pages.indices, id: \.self) { i in
                Capsule()
                    .fill(i == page ? Theme.accent : Theme.hairline)
                    .frame(width: i == page ? 22 : 7, height: 7)
            }
        }
        .accessibilityHidden(true)
    }

    private var tierPicker: some View {
        VStack(spacing: 8) {
            SectionLabel(text: "I'm focusing on")
            Picker("Focus", selection: $preferredTier) {
                ForEach(WordTier.allCases) { tier in
                    Text(tier.label).tag(tier.rawValue)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}

private struct OnboardPage {
    let icon: String
    let title: String
    let body: String
}
