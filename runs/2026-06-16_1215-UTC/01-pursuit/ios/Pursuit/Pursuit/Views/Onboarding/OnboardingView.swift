import SwiftUI

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
        Page(symbol: "list.bullet.rectangle.portrait",
             title: "One home for your job hunt",
             body: "Stop juggling spreadsheets and browser tabs. Track every application from saved to offer in a single, private pipeline."),
        Page(symbol: "arrow.left.arrow.right.circle.fill",
             title: "Move roles through stages",
             body: "Swipe to advance an application, log interviews and contacts, and keep a clear timeline of everything that happened."),
        Page(symbol: "chart.bar.xaxis",
             title: "Know what's working",
             body: "See your response, interview and offer rates, your weekly cadence, and where your best leads come from."),
        Page(symbol: "lock.shield.fill",
             title: "Private and yours",
             body: "Everything stays on your device — no account, no subscription. Pursuit Pro is a one-time unlock when you need more.")
    ]

    var body: some View {
        ZStack {
            Theme.heroGradient
                .opacity(0.10)
                .ignoresSafeArea()
            Theme.bg.opacity(0.6).ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, item in
                        OnboardingPage(symbol: item.symbol, title: item.title, body: item.body, animate: !reduceMotion)
                            .tag(index)
                            .padding(.horizontal, 28)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                VStack(spacing: 12) {
                    Button {
                        Haptics.impact(.medium, enabled: settings.hapticsEnabled)
                        if page < pages.count - 1 {
                            withAnimation(reduceMotion ? nil : .easeInOut) { page += 1 }
                        } else {
                            finish()
                        }
                    } label: {
                        Text(page < pages.count - 1 ? "Continue" : "Get started")
                            .font(Theme.rounded(17, .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(Theme.accent, in: RoundedRectangle(cornerRadius: Theme.radiusM, style: .continuous))
                            .foregroundStyle(.white)
                    }
                    .accessibilityHint(page < pages.count - 1 ? "Goes to the next page" : "Enters the app")

                    Button("Skip") { finish() }
                        .font(Theme.rounded(15, .medium))
                        .foregroundStyle(Theme.inkSoft)
                        .opacity(page < pages.count - 1 ? 1 : 0)
                        .disabled(page == pages.count - 1)
                        .accessibilityHidden(page == pages.count - 1)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 24)
            }
        }
    }

    private func finish() {
        Haptics.notify(.success, enabled: settings.hapticsEnabled)
        withAnimation(reduceMotion ? nil : .easeInOut) {
            hasOnboarded = true
        }
    }
}

private struct OnboardingPage: View {
    let symbol: String
    let title: String
    let body: String
    let animate: Bool
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 12)
            ZStack {
                Circle()
                    .fill(Theme.accent.opacity(0.12))
                    .frame(width: 150, height: 150)
                Image(systemName: symbol)
                    .font(.system(size: 62, weight: .regular))
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
            }
            .scaleEffect(appeared || !animate ? 1 : 0.85)
            .opacity(appeared || !animate ? 1 : 0)

            VStack(spacing: 12) {
                Text(title)
                    .font(Theme.rounded(28, .bold))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                Text(body)
                    .font(Theme.rounded(17))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .onAppear {
            guard animate else { return }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { appeared = true }
        }
        .accessibilityElement(children: .combine)
    }
}
