import SwiftUI

private struct OnboardPage: Identifiable {
    let id = UUID()
    let systemImage: String
    let title: String
    let body: String
}

/// Three-page onboarding explaining Sigma's value, gated by `hasOnboarded`.
struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    private let pages: [OnboardPage] = [
        OnboardPage(systemImage: "function",
                    title: "A calculator that thinks",
                    body: "Type whole expressions with parentheses, powers and scientific functions. Sigma evaluates them properly — no more clearing and starting over."),
        OnboardPage(systemImage: "list.bullet.rectangle.portrait",
                    title: "Everything is kept",
                    body: "A searchable history tape records every result. Tap any line to drop its value back into the keypad and keep going."),
        OnboardPage(systemImage: "arrow.left.arrow.right",
                    title: "Convert & compute in bases",
                    body: "Switch between units across nine categories, or read any integer in DEC, HEX, BIN and OCT at once with full bitwise operations.")
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
                .tabViewStyle(.page(indexDisplayMode: .never))

                pageDots
                    .padding(.bottom, 8)

                Button(action: advance) {
                    Text(page == pages.count - 1 ? "Get Started" : "Continue")
                        .font(Theme.rounded(18, .semibold))
                        .foregroundStyle(Theme.accentInk)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Theme.accent)
                        )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
                .accessibilityHint(page == pages.count - 1 ? "Finishes setup and opens Sigma" : "Goes to the next page")

                Button("Skip") { finish() }
                    .font(Theme.rounded(15))
                    .foregroundStyle(Theme.inkSoft)
                    .padding(.bottom, 16)
            }
        }
    }

    private func pageView(_ item: OnboardPage) -> some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Theme.surface)
                    .frame(width: 132, height: 132)
                    .shadow(color: Theme.keyShadow.opacity(0.4), radius: 14, y: 6)
                Image(systemName: item.systemImage)
                    .font(.system(size: 56, weight: .regular))
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
            }
            VStack(spacing: 12) {
                Text(item.title)
                    .font(Theme.rounded(28, .bold))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                Text(item.body)
                    .font(Theme.rounded(17))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
            }
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 12)
        .accessibilityElement(children: .combine)
    }

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<pages.count, id: \.self) { index in
                Capsule()
                    .fill(index == page ? Theme.accent : Theme.hairline)
                    .frame(width: index == page ? 22 : 8, height: 8)
                    .animation(reduceMotion ? .none : .spring(response: 0.3, dampingFraction: 0.8), value: page)
            }
        }
        .accessibilityHidden(true)
    }

    private func advance() {
        Haptics.selection(enabled: settings.hapticsEnabled)
        if page < pages.count - 1 {
            withAnimation(reduceMotion ? .none : .easeInOut) { page += 1 }
        } else {
            finish()
        }
    }

    private func finish() {
        Haptics.success(enabled: settings.hapticsEnabled)
        hasOnboarded = true
    }
}
