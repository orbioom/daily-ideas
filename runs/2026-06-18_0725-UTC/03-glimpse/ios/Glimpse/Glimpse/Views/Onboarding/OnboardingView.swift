import SwiftUI

/// Multi-page onboarding that explains the ritual and sets `hasOnboarded`.
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
        Page(symbol: "camera.aperture",
             title: "One moment a day",
             body: "Glimpse is a gentle ritual: a single photo, a short line, and how the day felt. That's it."),
        Page(symbol: "rectangle.stack.fill",
             title: "Watch a life add up",
             body: "Your moments become a warm timeline, a calendar of color, and a streak worth keeping."),
        Page(symbol: "sparkles",
             title: "Remember, beautifully",
             body: "Glimpse resurfaces moments from this day in years past — and your favorites — when you least expect it."),
        Page(symbol: "lock.shield.fill",
             title: "Private by design",
             body: "Everything stays on your device. No account, no feed, no pressure. Just your days.")
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, item in
                    pageView(item)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(reduceMotion ? nil : .easeInOut, value: page)

            controls
        }
        .background(Theme.bg.ignoresSafeArea())
    }

    private func pageView(_ item: Page) -> some View {
        VStack(spacing: 22) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Theme.heroGradient.opacity(0.18))
                    .frame(width: 180, height: 180)
                Image(systemName: item.symbol)
                    .font(.system(size: 72, weight: .light))
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
            }
            Text(item.title)
                .font(Theme.rounded(28, .bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text(item.body)
                .font(Theme.bodyFont)
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 32)
            Spacer()
        }
        .padding()
        .accessibilityElement(children: .combine)
    }

    private var controls: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Capsule()
                        .fill(index == page ? Theme.accent : Theme.hairline)
                        .frame(width: index == page ? 22 : 8, height: 8)
                        .animation(reduceMotion ? nil : .spring(response: 0.3), value: page)
                }
            }
            .accessibilityHidden(true)

            PrimaryButton(title: page < pages.count - 1 ? "Continue" : "Start capturing", symbol: nil) {
                Haptics.tap(settings.hapticsEnabled)
                if page < pages.count - 1 {
                    withAnimation(reduceMotion ? nil : .easeInOut) { page += 1 }
                } else {
                    finish()
                }
            }
            .padding(.horizontal, 20)

            Button("Skip") {
                finish()
            }
            .font(Theme.rounded(14, .semibold))
            .foregroundStyle(Theme.inkSoft)
            .opacity(page < pages.count - 1 ? 1 : 0)
            .disabled(page == pages.count - 1)
        }
        .padding(.bottom, 28)
    }

    private func finish() {
        Haptics.success(settings.hapticsEnabled)
        withAnimation(reduceMotion ? nil : .easeInOut) {
            hasOnboarded = true
        }
    }
}
