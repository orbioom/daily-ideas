import SwiftUI

/// First-run onboarding, gated by @AppStorage("hasOnboarded").
struct OnboardingView: View {
    @AppStorage(PrefKey.hasOnboarded) private var hasOnboarded: Bool = false
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    private struct Slide: Identifiable {
        let id = UUID()
        let symbol: String
        let title: String
        let body: String
    }

    private let slides: [Slide] = [
        .init(symbol: "fork.knife",
              title: "Welcome to Galley",
              body: "Your warm, all-in-one kitchen toolkit — convert, scale, substitute and time, all in one calm place."),
        .init(symbol: "arrow.left.arrow.right",
              title: "Density-aware conversions",
              body: "Cups to grams, tablespoons to millilitres — pick an ingredient and Galley uses its real density. Results read in friendly fractions."),
        .init(symbol: "slider.horizontal.3",
              title: "Scale & substitute",
              body: "Resize any recipe by servings or factor, see weights, and find a substitution when you're missing an ingredient."),
        .init(symbol: "timer",
              title: "Many timers at once",
              body: "Run a kitchenful of named timers side by side. They keep perfect time and survive a relaunch.")
    ]

    var body: some View {
        ZStack {
            GalleyBackground()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(slides.enumerated()), id: \.element.id) { idx, slide in
                        slideView(slide)
                            .tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(reduceMotion ? nil : .easeInOut, value: page)

                pageDots
                    .padding(.bottom, 8)

                controls
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
            }
        }
    }

    private func slideView(_ slide: Slide) -> some View {
        VStack(spacing: 22) {
            Spacer()
            ZStack {
                Circle()
                    .fill(GalleyTheme.terracotta.opacity(0.14))
                    .frame(width: 150, height: 150)
                Image(systemName: slide.symbol)
                    .font(.system(size: 62, weight: .regular))
                    .foregroundStyle(GalleyTheme.terracotta)
            }
            .accessibilityHidden(true)
            Text(slide.title)
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(GalleyTheme.primaryText(scheme))
                .multilineTextAlignment(.center)
            Text(slide.body)
                .font(.body)
                .foregroundStyle(GalleyTheme.secondaryText(scheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(slide.title). \(slide.body)")
    }

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(slides.indices, id: \.self) { i in
                Capsule()
                    .fill(i == page ? GalleyTheme.terracotta : GalleyTheme.secondaryText(scheme).opacity(0.3))
                    .frame(width: i == page ? 22 : 8, height: 8)
                    .animation(reduceMotion ? nil : .spring(duration: 0.3), value: page)
            }
        }
        .accessibilityHidden(true)
    }

    private var controls: some View {
        VStack(spacing: 10) {
            Button(page == slides.count - 1 ? "Start cooking" : "Next") {
                if page == slides.count - 1 {
                    hasOnboarded = true
                } else {
                    withAnimation(reduceMotion ? nil : .easeInOut) { page += 1 }
                }
            }
            .buttonStyle(GalleyPrimaryButtonStyle())
            .accessibilityHint(page == slides.count - 1 ? "Finishes setup and opens Galley" : "Goes to the next slide")

            if page < slides.count - 1 {
                Button("Skip") { hasOnboarded = true }
                    .font(.subheadline)
                    .foregroundStyle(GalleyTheme.secondaryText(scheme))
            }
        }
    }
}
