import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    private struct Slide: Identifiable {
        let id = UUID()
        let symbol: String
        let title: String
        let body: String
    }

    private let slides: [Slide] = [
        Slide(symbol: "calendar.day.timeline.left",
              title: "Plan trips day by day",
              body: "Every trip becomes an ordered timeline — one day at a time, from arrival to departure."),
        Slide(symbol: "checklist",
              title: "Pack with confidence",
              body: "A categorized checklist with starter templates means you never forget your passport again."),
        Slide(symbol: "chart.pie.fill",
              title: "Know your budget",
              body: "Track planned costs and real expenses, see a category breakdown, and stay on budget."),
        Slide(symbol: "airplane.departure",
              title: "Private & offline",
              body: "No account, no cloud, no ads. Your travel plans live only on your device.")
    ]

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(slides.enumerated()), id: \.element.id) { idx, slide in
                        slideView(slide)
                            .tag(idx)
                            .padding(.horizontal, 28)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                VStack(spacing: 12) {
                    Button {
                        Haptics.tap()
                        if page < slides.count - 1 {
                            withAnimation(reduceMotion ? nil : .easeInOut) { page += 1 }
                        } else {
                            finish()
                        }
                    } label: {
                        Text(page < slides.count - 1 ? "Continue" : "Start planning")
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Button("Skip") { finish() }
                        .font(Theme.font(.subheadline))
                        .foregroundStyle(Theme.textSecondary)
                        .opacity(page < slides.count - 1 ? 1 : 0)
                        .disabled(page == slides.count - 1)
                        .accessibilityHidden(page == slides.count - 1)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 24)
            }
        }
    }

    private func slideView(_ slide: Slide) -> some View {
        VStack(spacing: 22) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Theme.accent.opacity(0.12))
                    .frame(width: 150, height: 150)
                Image(systemName: slide.symbol)
                    .font(.system(size: 62, weight: .medium))
                    .foregroundStyle(Theme.accent)
            }
            .accessibilityHidden(true)
            Text(slide.title)
                .font(Theme.font(.title, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
            Text(slide.body)
                .font(Theme.font(.body))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(slide.title). \(slide.body)")
    }

    private func finish() {
        Haptics.success()
        withAnimation(reduceMotion ? nil : .easeInOut) {
            hasOnboarded = true
        }
    }
}
