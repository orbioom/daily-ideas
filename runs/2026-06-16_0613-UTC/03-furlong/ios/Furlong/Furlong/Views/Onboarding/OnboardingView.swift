import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    private struct Page: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let body: String
    }

    private let pages: [Page] = [
        Page(icon: "signpost.right.fill",
             title: "Every mile counts",
             body: "Furlong turns the miles you already drive for work into real tax deductions — logged in seconds, kept private on your device."),
        Page(icon: "briefcase.fill",
             title: "Built for the self-employed",
             body: "Rideshare, delivery, freelance, contractor. Tag trips business, medical, charity or personal and let Furlong do the IRS math."),
        Page(icon: "chart.pie.fill",
             title: "See your deduction grow",
             body: "Live dashboard, year reports, and a standard-mileage-vs-actual-expense comparison so you claim the bigger number."),
        Page(icon: "lock.shield.fill",
             title: "Private. One-time. No login.",
             body: "No subscriptions, no accounts, no cloud. Everything stays on your phone. Furlong Pro is a single \(Pro.price) unlock — that's it.")
    ]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, p in
                        pageView(p)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                indicator
                    .padding(.top, 8)

                controls
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 28)
            }
        }
    }

    private func pageView(_ p: Page) -> some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Theme.accentSoft)
                    .frame(width: 150, height: 150)
                Image(systemName: p.icon)
                    .font(.system(size: 62, weight: .semibold))
                    .foregroundStyle(Theme.accent)
            }
            .accessibilityHidden(true)

            VStack(spacing: 14) {
                Text(p.title)
                    .font(Theme.rounded(28, .bold))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                Text(p.body)
                    .font(Theme.rounded(17))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
            }
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 8)
    }

    private var indicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<pages.count, id: \.self) { i in
                Capsule()
                    .fill(i == page ? Theme.accent : Theme.hairline)
                    .frame(width: i == page ? 22 : 8, height: 8)
                    .animation(reduceMotion ? nil : .spring(response: 0.3), value: page)
            }
        }
        .accessibilityHidden(true)
    }

    private var controls: some View {
        VStack(spacing: 12) {
            PrimaryButton(title: page == pages.count - 1 ? "Start tracking" : "Continue",
                          symbol: page == pages.count - 1 ? "checkmark" : "arrow.right") {
                if page == pages.count - 1 {
                    finish()
                } else {
                    withAnimation(reduceMotion ? nil : .easeInOut) { page += 1 }
                }
            }
            Button("Skip") { finish() }
                .font(Theme.rounded(15, .medium))
                .foregroundStyle(Theme.inkSoft)
                .opacity(page == pages.count - 1 ? 0 : 1)
                .disabled(page == pages.count - 1)
        }
    }

    private func finish() {
        Haptics.success(settings.hapticsEnabled)
        withAnimation(reduceMotion ? nil : .easeInOut) {
            hasOnboarded = true
        }
    }
}
