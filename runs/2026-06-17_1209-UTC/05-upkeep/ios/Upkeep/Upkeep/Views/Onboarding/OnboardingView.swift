import SwiftUI
import SwiftData

/// First-run onboarding, gated by the persisted `hasOnboarded` flag.
struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("didSeed") private var didSeed = false
    @State private var page = 0

    private struct Slide: Identifiable {
        let id = UUID()
        let symbol: String
        let title: String
        let body: String
    }

    private let slides: [Slide] = [
        Slide(symbol: "house.and.flag",
              title: "Welcome to Upkeep",
              body: "A calm, private place to stay on top of the recurring upkeep that keeps a home healthy."),
        Slide(symbol: "calendar.badge.clock",
              title: "Smart due dates",
              body: "Set how often each task recurs — including seasonal jobs — and Upkeep tracks what's overdue, due soon, and fresh."),
        Slide(symbol: "heart.text.square",
              title: "Home health & cost",
              body: "A single health score, a cost log, and a ready-made starter checklist of the tasks every home needs.")
    ]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(slides.enumerated()), id: \.element.id) { index, slide in
                        slideView(slide).tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))

                VStack(spacing: 12) {
                    PrimaryButton(title: page == slides.count - 1 ? "Get started" : "Continue") {
                        advance()
                    }
                    if page == slides.count - 1 {
                        Text("Your data stays on this device. No account required.")
                            .font(Theme.rounded(12))
                            .foregroundStyle(Theme.inkFaint)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }

    private func slideView(_ slide: Slide) -> some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: slide.symbol)
                .font(.system(size: 72, weight: .light))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text(slide.title)
                .font(Theme.serif(28, .bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text(slide.body)
                .font(Theme.rounded(17))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 28)
            Spacer()
        }
        .padding()
    }

    private func advance() {
        Haptics.tap(settings.hapticsEnabled)
        if page < slides.count - 1 {
            withAnimation { page += 1 }
        } else {
            // Seed immediately so the first screen is populated.
            var seeded = didSeed
            SeedData.seedIfNeeded(context: context, didSeed: &seeded)
            didSeed = seeded
            hasOnboarded = true
        }
    }
}
