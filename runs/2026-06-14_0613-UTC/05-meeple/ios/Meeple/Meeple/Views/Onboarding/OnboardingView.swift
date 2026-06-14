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
        .init(symbol: "square.grid.2x2.fill",
              title: "Your shelf, organised",
              body: "Catalog every game you own, want, or have sold — with generated covers, ratings, weight and player counts."),
        .init(symbol: "dice.fill",
              title: "Log every play",
              body: "Record who played, scores and winners. Meeple snapshots names so your history stays intact forever."),
        .init(symbol: "chart.bar.xaxis",
              title: "Stats that come alive",
              body: "Most-played, win rates, plays-per-month, and your gaming H-index — the metric serious players love."),
        .init(symbol: "sparkles",
              title: "What should we play?",
              body: "Tell Meeple your group size and time, and it surfaces eligible games — plus a Surprise Me pick.")
    ]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(slides.enumerated()), id: \.element.id) { idx, slide in
                        slideView(slide).tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .animation(reduceMotion ? nil : .easeInOut, value: page)

                VStack(spacing: 12) {
                    Button {
                        if page < slides.count - 1 {
                            withAnimation(reduceMotion ? nil : .easeInOut) { page += 1 }
                        } else {
                            hasOnboarded = true
                        }
                    } label: {
                        Text(page < slides.count - 1 ? "Continue" : "Start Playing")
                            .font(Theme.rounded(17, .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Skip") { hasOnboarded = true }
                        .font(Theme.rounded(15))
                        .foregroundStyle(Theme.textSecondary)
                        .opacity(page < slides.count - 1 ? 1 : 0)
                        .disabled(page >= slides.count - 1)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }

    private func slideView(_ slide: Slide) -> some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle().fill(Theme.accent.opacity(0.14)).frame(width: 160, height: 160)
                Image(systemName: slide.symbol)
                    .font(.system(size: 64, weight: .semibold))
                    .foregroundStyle(Theme.accent)
            }
            .accessibilityHidden(true)
            Text(slide.title)
                .font(Theme.serif(28, .bold))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
            Text(slide.body)
                .font(Theme.rounded(16))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
            Spacer()
        }
        .padding()
        .accessibilityElement(children: .combine)
    }
}
