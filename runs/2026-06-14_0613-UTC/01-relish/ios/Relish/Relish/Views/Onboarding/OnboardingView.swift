import SwiftUI

/// Three-page onboarding explaining the pairwise ranking idea. Gated by hasOnboarded.
struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    private struct Page: Identifiable {
        let id = UUID()
        let symbol: String
        let title: String
        let body: String
    }

    private let pages: [Page] = [
        Page(symbol: "fork.knife.circle.fill",
             title: "Every place, ranked",
             body: "Relish keeps a private, ordered list of every restaurant you've been to — no logins, no feed, all offline."),
        Page(symbol: "arrow.left.arrow.right.circle.fill",
             title: "Rank by comparing",
             body: "Add a place, pick how you felt — Loved, Liked, or Okay — then answer a few quick \"which was better?\" matchups. Relish slots it in exactly where it belongs."),
        Page(symbol: "number.circle.fill",
             title: "Scores that mean something",
             body: "Your 0–10 scores come from your own rankings, not arbitrary stars. The more you add, the sharper your taste map gets.")
    ]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, item in
                        pageView(item)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .animation(reduceMotion ? nil : .easeInOut, value: page)

                VStack(spacing: 12) {
                    PrimaryButton(title: page == pages.count - 1 ? "Start ranking" : "Next",
                                  systemImage: page == pages.count - 1 ? "checkmark" : "arrow.right") {
                        advance()
                    }
                    Button("Skip") { finish() }
                        .font(Theme.rounded(15))
                        .foregroundStyle(Theme.inkSoft)
                        .opacity(page == pages.count - 1 ? 0 : 1)
                        .disabled(page == pages.count - 1)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }

    private func pageView(_ item: Page) -> some View {
        VStack(spacing: 22) {
            Spacer()
            Image(systemName: item.symbol)
                .font(.system(size: 76, weight: .regular))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text(item.title)
                .font(Theme.serif(30, .bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text(item.body)
                .font(Theme.rounded(17))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 32)
            Spacer()
        }
        .padding(.bottom, 40)
    }

    private func advance() {
        if page < pages.count - 1 {
            Haptics.tap(settings.hapticsEnabled)
            withAnimation(reduceMotion ? nil : .easeInOut) { page += 1 }
        } else {
            finish()
        }
    }

    private func finish() {
        Haptics.success(settings.hapticsEnabled)
        hasOnboarded = true
    }
}
