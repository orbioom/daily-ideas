import SwiftUI

/// First-run onboarding. Three calm pages, then sets `hasOnboarded`.
struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @State private var page = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private struct Page: Identifiable {
        let id = UUID()
        let systemImage: String
        let title: String
        let body: String
    }

    private let pages: [Page] = [
        Page(systemImage: "globe",
             title: "See the whole world",
             body: "Learn every country, capital and flag — across all six continents — at your own pace."),
        Page(systemImage: "brain.head.profile",
             title: "Practice that adapts",
             body: "Peregrine quietly drills your weak spots, weighting questions toward what you haven't mastered yet."),
        Page(systemImage: "flame.fill",
             title: "A little every day",
             body: "Take the shared Daily Challenge, build a streak, and watch your mastery grow on the map.")
    ]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, item in
                        pageView(item)
                            .tag(index)
                            .padding(.horizontal, 28)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                pageDots
                    .padding(.bottom, 18)

                controls
                    .padding(.horizontal, 28)
                    .padding(.bottom, 24)
            }
        }
    }

    private func pageView(_ item: Page) -> some View {
        VStack(spacing: 22) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Theme.accentSoft)
                    .frame(width: 150, height: 150)
                Image(systemName: item.systemImage)
                    .font(.system(size: 64, weight: .regular))
                    .foregroundStyle(Theme.accent)
            }
            .accessibilityHidden(true)
            Text(item.title)
                .font(Theme.rounded(28, .bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text(item.body)
                .font(Theme.rounded(17))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Spacer()
        }
    }

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(pages.indices, id: \.self) { i in
                Capsule()
                    .fill(i == page ? Theme.accent : Theme.hairline)
                    .frame(width: i == page ? 22 : 8, height: 8)
                    .animation(reduceMotion ? nil : .spring(duration: 0.3), value: page)
            }
        }
        .accessibilityHidden(true)
    }

    private var controls: some View {
        VStack(spacing: 12) {
            if page < pages.count - 1 {
                PrimaryButton(title: "Continue", systemImage: "arrow.right") {
                    withAnimation(reduceMotion ? nil : .easeInOut) { page += 1 }
                }
                Button("Skip") { finish() }
                    .font(Theme.rounded(15, .medium))
                    .foregroundStyle(Theme.inkSoft)
            } else {
                PrimaryButton(title: "Start exploring", systemImage: "globe") { finish() }
            }
        }
    }

    private func finish() {
        Haptics.tap()
        hasOnboarded = true
    }
}

#Preview {
    OnboardingView()
}
