import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @EnvironmentObject private var settings: AppSettings
    @State private var page = 0

    private struct Slide {
        let icon: String
        let title: String
        let body: String
    }

    private let slides: [Slide] = [
        Slide(icon: "moon.stars.fill",
              title: "Welcome to Arcana",
              body: "A calm, beautiful tarot companion — a daily card, classic spreads, a private journal, and the full 78-card deck to study."),
        Slide(icon: "sun.max.fill",
              title: "A Card a Day",
              body: "Each day reveals one card, the same for the whole day. Sit with it, read its meaning, and jot a short reflection."),
        Slide(icon: "rectangle.3.group.fill",
              title: "Spreads & Journal",
              body: "Draw a Three-Card or Yes/No reading for free, save it to your journal, and look back on how your story unfolds."),
        Slide(icon: "books.vertical.fill",
              title: "Learn the Whole Deck",
              body: "Every card, Major and Minor, with genuine upright and reversed meanings — yours to browse and learn, free.")
    ]

    var body: some View {
        ZStack {
            Theme.skyGradient.ignoresSafeArea()
            Starfield(starCount: 90).ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(slides.indices, id: \.self) { i in
                        slideView(slides[i]).tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))

                VStack(spacing: 14) {
                    if page == slides.count - 1 {
                        ReflectionNote()
                    }
                    PrimaryButton(title: page == slides.count - 1 ? "Begin" : "Continue",
                                  icon: page == slides.count - 1 ? "sparkles" : nil) {
                        Haptics.tap(settings.hapticsEnabled)
                        if page == slides.count - 1 {
                            hasOnboarded = true
                        } else {
                            withAnimation { page += 1 }
                        }
                    }
                    Button("Skip") {
                        hasOnboarded = true
                    }
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSoft)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 28)
            }
        }
    }

    private func slideView(_ slide: Slide) -> some View {
        VStack(spacing: 22) {
            Spacer()
            Image(systemName: slide.icon)
                .font(.system(size: 76))
                .foregroundStyle(Theme.gold)
                .shadow(color: Theme.gold.opacity(0.5), radius: 16)
                .accessibilityHidden(true)
            Text(slide.title)
                .font(Theme.serif(30, .bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text(slide.body)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.inkSoft)
                .padding(.horizontal, 32)
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }
}
