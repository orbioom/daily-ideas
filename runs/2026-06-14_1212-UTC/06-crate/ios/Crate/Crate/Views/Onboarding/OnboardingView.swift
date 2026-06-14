import SwiftUI

/// Three-page onboarding in Crate's record-store language. Sets hasOnboarded on finish.
struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    private struct Page: Identifiable {
        let id = UUID()
        let symbol: String
        let hue: Double
        let title: String
        let body: String
    }

    private let pages: [Page] = [
        Page(symbol: "square.stack.3d.up.fill", hue: 0.08,
             title: "Your crate, catalogued",
             body: "Crate keeps a private, beautiful catalogue of every record you own — tracklists, pressings, condition grades and value. No marketplace, no clutter, all offline."),
        Page(symbol: "opticaldisc.fill", hue: 0.55,
             title: "Log every spin",
             body: "Tap once to log a listen. Crate tracks what you play most, what's gathering dust, and your spins over time — your real listening life on wax."),
        Page(symbol: "dial.medium.fill", hue: 0.30,
             title: "\"What should I spin?\"",
             body: "Can't decide? Crate surprises you with a pick from your shelves, leaning toward records you haven't played in a while. Drop the needle.")
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
                    PrimaryButton(title: page == pages.count - 1 ? "Start digging" : "Next",
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
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                VinylDisc(labelHue: item.hue, labelFraction: 0.5)
                    .frame(width: 168, height: 168)
                Image(systemName: item.symbol)
                    .font(.system(size: 46, weight: .semibold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.4), radius: 3, y: 1)
                    .accessibilityHidden(true)
            }
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
