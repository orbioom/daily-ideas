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
        Page(icon: "fork.knife",
             title: "Crisp, every time",
             body: "Exact air-fryer temps and times for 70+ foods — fresh or from frozen, scaled to your portion."),
        Page(icon: "timer",
             title: "Run every basket at once",
             body: "Start real multi-timers that keep counting in the background and survive a relaunch. No more burnt fries."),
        Page(icon: "arrow.left.arrow.right",
             title: "Convert any recipe",
             body: "Turn oven instructions into air-fryer settings, flip °F↔°C and g↔oz, and check safe doneness temps."),
    ]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { idx, p in
                        pageView(p)
                            .tag(idx)
                            .padding(.horizontal, 28)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                VStack(spacing: 12) {
                    PrimaryButton(
                        title: page == pages.count - 1 ? "Start cooking" : "Next",
                        systemImage: page == pages.count - 1 ? "flame.fill" : "chevron.right"
                    ) {
                        Haptics.selection(enabled: settings.hapticsEnabled)
                        if page == pages.count - 1 {
                            finish()
                        } else {
                            withAnimation(reduceMotion ? .none : .easeInOut) { page += 1 }
                        }
                    }
                    Button("Skip") {
                        finish()
                    }
                    .font(Theme.roundedStyle(.subheadline, .semibold))
                    .foregroundStyle(Theme.inkSoft)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 28)
            }
        }
    }

    private func pageView(_ p: Page) -> some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Theme.surfaceAlt)
                    .frame(width: 150, height: 150)
                Image(systemName: p.icon)
                    .font(.system(size: 64, weight: .bold))
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
            }
            Text(p.title)
                .font(Theme.roundedStyle(.largeTitle, .bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text(p.body)
                .font(Theme.roundedStyle(.body))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
            Spacer()
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }

    private func finish() {
        Haptics.notify(.success, enabled: settings.hapticsEnabled)
        withAnimation(reduceMotion ? .none : .easeInOut) { hasOnboarded = true }
    }
}
