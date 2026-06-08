import SwiftUI

struct OnboardingView: View {
    @Binding var done: Bool
    @State private var page = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let pages: [(symbol: String, title: String, body: String)] = [
        ("cloud.sun.fill", "Catch the tide",
         "A ten-second check-in: how you feel, what you were doing, an optional note. No clunky journaling, no pressure."),
        ("tag.fill", "Tag your days",
         "Attach activities like exercise, work, or friends. Over time Tide learns what lifts you and what drags you down."),
        ("chart.xyaxis.line", "See the pattern",
         "A calendar of colour, a mood trend, and honest correlations — the quiet signal under noisy days. Everything stays on your device."),
    ]

    var body: some View {
        ZStack {
            Brand.pageBackground
            VStack(spacing: 0) {
                Spacer()
                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { i in
                        VStack(spacing: 22) {
                            Image(systemName: pages[i].symbol)
                                .font(.system(size: 64, weight: .light))
                                .foregroundStyle(Brand.inkGradient)
                                .accessibilityHidden(true)
                            Text(pages[i].title)
                                .font(.largeTitle.weight(.bold))
                                .foregroundStyle(Brand.text)
                                .multilineTextAlignment(.center)
                            Text(pages[i].body)
                                .font(.body)
                                .foregroundStyle(Brand.text2)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 28)
                        }
                        .tag(i).padding()
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .frame(height: 360)
                Spacer()
                Button(page == pages.count - 1 ? "Start checking in" : "Continue") {
                    if page == pages.count - 1 {
                        Haptics.success()
                        withAnimation(reduceMotion ? nil : Brand.ease()) { done = true }
                    } else {
                        withAnimation(reduceMotion ? nil : Brand.ease()) { page += 1 }
                    }
                }
                .buttonStyle(InkButtonStyle())
                .padding(.horizontal, 24).padding(.bottom, 20)
            }
        }
    }
}
