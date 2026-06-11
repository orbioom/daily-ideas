import SwiftUI

struct OnboardingView: View {
    @Binding var isComplete: Bool
    @State private var page = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let pages: [OnboardPage] = [
        OnboardPage(icon: "film.stack", title: "Track Everything You Watch", body: "Movies, series, documentaries — log them all in one beautiful place."),
        OnboardPage(icon: "tv.and.hifispeaker.fill", title: "Episode by Episode", body: "For shows, mark individual episodes as you go. Reel keeps your progress perfectly."),
        OnboardPage(icon: "chart.bar.fill", title: "See Your Viewing Life", body: "Hours watched, favourite genres, ratings — your watch history becomes insights.")
    ]

    var body: some View {
        ZStack {
            Theme.bgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { idx in
                        PageSlide(page: pages[idx])
                            .tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxHeight: .infinity)

                VStack(spacing: 24) {
                    HStack(spacing: 8) {
                        ForEach(pages.indices, id: \.self) { idx in
                            Capsule()
                                .fill(idx == page ? Theme.gold : Theme.silver.opacity(0.4))
                                .frame(width: idx == page ? 24 : 8, height: 8)
                                .animation(reduceMotion ? .none : .spring(response: 0.3), value: page)
                        }
                    }

                    Button(page < pages.count - 1 ? "Next" : "Get Started") {
                        if page < pages.count - 1 {
                            withAnimation(reduceMotion ? .none : .easeInOut) { page += 1 }
                        } else {
                            isComplete = true
                        }
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.gold)
                    .foregroundStyle(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 32)
                    .accessibilityHint(page < pages.count - 1 ? "Go to the next onboarding page" : "Finish onboarding and open the app")
                }
                .padding(.bottom, 48)
            }
        }
    }
}

private struct OnboardPage {
    let icon: String
    let title: String
    let body: String
}

private struct PageSlide: View {
    let page: OnboardPage

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            Image(systemName: page.icon)
                .font(.system(size: 80))
                .foregroundStyle(Theme.gold)
                .accessibilityHidden(true)

            VStack(spacing: 12) {
                Text(page.title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.center)

                Text(page.body)
                    .font(.body)
                    .foregroundStyle(Theme.silver)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            Spacer()
        }
    }
}
