import SwiftUI

/// A 3-page intro explaining the core ideas: card of the day, readings, and the
/// journal. The persisted `arcana.onboarded` flag gates the rest of the app.
struct OnboardingView: View {
    @AppStorage(PrefKey.onboarded) private var onboarded = false
    @State private var page = 0

    private let pages: [OnboardPage] = [
        OnboardPage(symbol: "moon.stars.fill",
                    title: "A card each day",
                    body: "Draw your Card of the Day for a calm, focused touchstone. It stays the same all day — a moment to reflect."),
        OnboardPage(symbol: "rectangle.portrait.on.rectangle.portrait",
                    title: "Readings that fit the question",
                    body: "Choose a spread — a single card, Past·Present·Future, the Celtic Cross — ask a question, and reveal each card one at a time."),
        OnboardPage(symbol: "book.closed.fill",
                    title: "Your private journal",
                    body: "Every reading is saved with your notes and reflections. Browse the full 78-card deck and watch your patterns emerge in Insights.")
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, p in
                    OnboardPageView(page: p)
                        .tag(index)
                        .padding(.horizontal, 28)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            VStack(spacing: 12) {
                Button(page == pages.count - 1 ? "Begin" : "Next") {
                    Haptics.tap()
                    if page == pages.count - 1 {
                        Haptics.success()
                        onboarded = true
                    } else {
                        withAnimation(Brand.ease()) { page += 1 }
                    }
                }
                .buttonStyle(InkButtonStyle())
                .accessibilityHint(page == pages.count - 1 ? "Finishes the introduction" : "Goes to the next page")

                if page < pages.count - 1 {
                    Button("Skip") {
                        Haptics.tap()
                        onboarded = true
                    }
                    .buttonStyle(.plain)
                    .font(.subheadline)
                    .foregroundStyle(Brand.text2)
                }
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 32)
        }
    }
}

private struct OnboardPage {
    let symbol: String
    let title: String
    let body: String
}

private struct OnboardPageView: View {
    let page: OnboardPage
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: page.symbol)
                .font(.system(size: 72, weight: .light))
                .foregroundStyle(Brand.magic)
                .accessibilityHidden(true)
            VStack(spacing: 14) {
                Text(page.title)
                    .font(.title.weight(.bold))
                    .foregroundStyle(Brand.text)
                    .multilineTextAlignment(.center)
                Text(page.body)
                    .font(.body)
                    .foregroundStyle(Brand.text2)
                    .multilineTextAlignment(.center)
            }
            Spacer()
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }
}
