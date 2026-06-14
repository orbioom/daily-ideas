import SwiftUI

/// Three-page onboarding in Sillage's warm editorial language. Gated by hasOnboarded.
struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    private struct Page: Identifiable {
        let id = UUID()
        let symbol: String
        let family: NoteFamily
        let title: String
        let body: String
    }

    private let pages: [Page] = [
        Page(symbol: "drop.fill", family: .amber,
             title: "Your private perfumery",
             body: "Catalog every bottle with its house, concentration, and full note pyramid. No ads, no feed — just your collection, beautifully kept."),
        Page(symbol: "moon.stars.fill", family: .woody,
             title: "What to wear tonight",
             body: "Pick a season and an occasion and Sillage suggests the right fragrance — favoring the ones you haven't reached for in a while. One tap logs the wear."),
        Page(symbol: "chart.pie.fill", family: .floral,
             title: "Learn your taste",
             body: "See your note-family map, season and occasion habits, and cost-per-wear. The bottles you actually love rise to the top.")
    ]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, item in
                        pageView(item).tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .animation(reduceMotion ? nil : .easeInOut, value: page)

                VStack(spacing: 12) {
                    PrimaryButton(title: page == pages.count - 1 ? "Start collecting" : "Next",
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
                Circle()
                    .fill(LinearGradient(colors: [item.family.hue, item.family.hueDeep],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 150, height: 150)
                Image(systemName: item.symbol)
                    .font(.system(size: 64, weight: .regular))
                    .foregroundStyle(.white)
            }
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
