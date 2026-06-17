import SwiftUI

private struct OnboardPage: Identifiable {
    let id = UUID()
    let symbol: String
    let title: String
    let body: String
    let tint: Color
}

struct OnboardingView: View {
    @AppStorage(PrefKey.hasOnboarded) private var hasOnboarded: Bool = false
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var index = 0

    private let pages: [OnboardPage] = [
        OnboardPage(symbol: "creditcard.and.123",
                    title: "See everything you pay",
                    body: "Track every subscription and recurring payment in one calm, private place — Netflix to your gym.",
                    tint: RecurTheme.violet),
        OnboardPage(symbol: "bell.badge",
                    title: "Catch trials before they bill",
                    body: "Recur flags free trials ending soon and reminds you before each renewal, so nothing sneaks up on you.",
                    tint: RecurTheme.amber),
        OnboardPage(symbol: "chart.pie",
                    title: "Know your real monthly cost",
                    body: "Any billing cycle is normalized to a true monthly and yearly total — with a clear breakdown by category.",
                    tint: RecurTheme.teal),
        OnboardPage(symbol: "lock.shield",
                    title: "Fully private, on your device",
                    body: "No account, no cloud, no tracking. Your finances never leave your iPhone. A one-time purchase, not a subscription.",
                    tint: RecurTheme.violetDeep)
    ]

    var body: some View {
        ZStack {
            RecurTheme.appBackground(scheme).ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $index) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { offset, page in
                        pageView(page).tag(offset)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(reduceMotion ? nil : .easeInOut, value: index)

                pageDots
                    .padding(.vertical, 18)

                controls
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
            }
        }
    }

    private func pageView(_ page: OnboardPage) -> some View {
        VStack(spacing: 26) {
            Spacer()
            ZStack {
                Circle()
                    .fill(page.tint.opacity(0.14))
                    .frame(width: 168, height: 168)
                Image(systemName: page.symbol)
                    .font(.system(size: 74, weight: .regular))
                    .foregroundStyle(page.tint)
            }
            .accessibilityHidden(true)
            VStack(spacing: 12) {
                Text(page.title)
                    .font(.title.weight(.bold))
                    .foregroundStyle(RecurTheme.primaryText(scheme))
                    .multilineTextAlignment(.center)
                Text(page.body)
                    .font(.body)
                    .foregroundStyle(RecurTheme.secondaryText(scheme))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
            }
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 16)
        .accessibilityElement(children: .combine)
    }

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(pages.indices, id: \.self) { i in
                Capsule()
                    .fill(i == index ? RecurTheme.violet : RecurTheme.secondaryText(scheme).opacity(0.3))
                    .frame(width: i == index ? 22 : 8, height: 8)
            }
        }
        .accessibilityHidden(true)
    }

    private var controls: some View {
        VStack(spacing: 12) {
            Button(index < pages.count - 1 ? "Continue" : "Get Started") {
                Haptics.light()
                if index < pages.count - 1 {
                    withAnimation(reduceMotion ? nil : .easeInOut) { index += 1 }
                } else {
                    finish()
                }
            }
            .buttonStyle(RecurPrimaryButtonStyle())

            Button("Skip") { finish() }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(RecurTheme.secondaryText(scheme))
                .opacity(index < pages.count - 1 ? 1 : 0)
                .disabled(index == pages.count - 1)
                .accessibilityHidden(index == pages.count - 1)
        }
    }

    private func finish() {
        Haptics.success()
        hasOnboarded = true
    }
}
