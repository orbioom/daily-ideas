import SwiftUI

private struct OnboardPage: Identifiable {
    let id = UUID()
    let symbol: String
    let title: String
    let body: String
}

/// Three-page onboarding explaining how to play. Sets `hasOnboarded` on finish.
struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var index = 0

    private let pages: [OnboardPage] = [
        OnboardPage(symbol: "circle.grid.cross.fill",
                    title: "Swipe to Spell",
                    body: "A wheel of letters sits at the bottom. Drag across them — or tap in order — to build a word."),
        OnboardPage(symbol: "square.grid.3x3.fill",
                    title: "Fill the Grid",
                    body: "Every word you find slots into an interlocking crossword. Clear them all to win the level."),
        OnboardPage(symbol: "sparkles",
                    title: "Collect & Unwind",
                    body: "Valid extra words become bonus treasures in your Word Jar. No ads, no timers — just calm.")
    ]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $index) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { i, page in
                        pageView(page).tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(reduceMotion ? nil : .easeInOut, value: index)

                pageDots

                VStack(spacing: 10) {
                    PrimaryButton(title: index == pages.count - 1 ? "Start Playing" : "Continue",
                                  systemImage: index == pages.count - 1 ? "play.fill" : "arrow.right") {
                        advance()
                    }
                    if index < pages.count - 1 {
                        SecondaryButton(title: "Skip") { finish() }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }

    private func pageView(_ page: OnboardPage) -> some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle().fill(Theme.accentSoft).frame(width: 140, height: 140)
                Image(systemName: page.symbol)
                    .font(.system(size: 60, weight: .bold))
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
            }
            Text(page.title)
                .font(Theme.rounded(28, .heavy))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text(page.body)
                .font(Theme.rounded(17))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 36)
            Spacer()
        }
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(page.title). \(page.body)")
    }

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<pages.count, id: \.self) { i in
                Capsule()
                    .fill(i == index ? Theme.accent : Theme.hairline)
                    .frame(width: i == index ? 22 : 8, height: 8)
                    .animation(reduceMotion ? nil : .spring(response: 0.3), value: index)
            }
        }
        .padding(.bottom, 20)
        .accessibilityHidden(true)
    }

    private func advance() {
        if index < pages.count - 1 {
            withAnimation(reduceMotion ? nil : .easeInOut) { index += 1 }
        } else {
            finish()
        }
    }

    private func finish() {
        hasOnboarded = true
    }
}
