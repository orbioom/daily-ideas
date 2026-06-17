import SwiftUI

/// First-run onboarding, gated by the persisted `hasOnboarded` flag.
struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded: Bool = false
    @Environment(\.colorScheme) private var scheme
    @State private var page = 0

    private struct Slide: Identifiable {
        let id = UUID()
        let systemImage: String
        let title: String
        let body: String
    }

    private let slides: [Slide] = [
        .init(systemImage: "house.fill",
              title: "Pass the real estate exam",
              body: "Practice the national portion with \(QuestionBank.all.count) exam-style questions across ten topics — each with a clear explanation."),
        .init(systemImage: "scope",
              title: "Study smarter, not longer",
              body: "Adaptive drills target your weakest topics, and a readiness score tells you when you're ready to test."),
        .init(systemImage: "lock.open.fill",
              title: "Yours for one price",
              body: "No subscriptions, no ads, fully offline and private. Practice as much as you want.")
    ]

    var body: some View {
        ZStack {
            Theme.background(scheme).ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(slides.enumerated()), id: \.element.id) { idx, slide in
                        VStack(spacing: 22) {
                            Spacer()
                            Image(systemName: slide.systemImage)
                                .font(.system(size: 72))
                                .foregroundStyle(Theme.accent)
                                .accessibilityHidden(true)
                            Text(slide.title)
                                .font(Theme.largeTitle)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(Theme.textPrimary(scheme))
                            Text(slide.body)
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(Theme.textSecondary(scheme))
                                .padding(.horizontal, 28)
                            Spacer()
                        }
                        .tag(idx)
                        .padding()
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))

                Button(page < slides.count - 1 ? "Continue" : "Start studying") {
                    if page < slides.count - 1 {
                        withAnimation { page += 1 }
                    } else {
                        hasOnboarded = true
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 12)

                Button("Skip") { hasOnboarded = true }
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary(scheme))
                    .padding(.bottom, 20)
            }
        }
    }
}
