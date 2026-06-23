import SwiftUI

/// Three-page onboarding. Completion flips the persisted `hasOnboarded` flag.
struct OnboardingView: View {
    var onFinish: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    private struct Page: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let body: String
        let tint: Color
    }

    private let pages: [Page] = [
        Page(icon: "calendar", title: "Plan your week",
             body: "Drop recipes onto any day and meal. A calm grid for the whole week — no spreadsheets.",
             tint: Theme.terracotta),
        Page(icon: "cart.fill", title: "Lists that build themselves",
             body: "Suppr adds up every ingredient across your plan and sorts it by aisle, scaled to your servings.",
             tint: Theme.amber),
        Page(icon: "cabinet.fill", title: "Skip what you already have",
             body: "Mark your pantry staples as on-hand and Suppr quietly leaves them off the shopping list.",
             tint: Theme.sage)
    ]

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, item in
                        pageView(item)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(reduceMotion ? nil : .easeInOut, value: page)

                indicators

                controls
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
            }
        }
    }

    private func pageView(_ item: Page) -> some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle()
                    .fill(item.tint.opacity(0.16))
                    .frame(width: 150, height: 150)
                Image(systemName: item.icon)
                    .font(.system(size: 64, weight: .medium))
                    .foregroundStyle(item.tint)
            }
            .accessibilityHidden(true)
            Text(item.title)
                .font(.title.bold())
                .foregroundStyle(Theme.primaryText)
                .multilineTextAlignment(.center)
            Text(item.body)
                .font(.body)
                .foregroundStyle(Theme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding()
    }

    private var indicators: some View {
        HStack(spacing: 8) {
            ForEach(pages.indices, id: \.self) { i in
                Capsule()
                    .fill(i == page ? Theme.terracotta : Theme.hairline)
                    .frame(width: i == page ? 22 : 8, height: 8)
                    .animation(reduceMotion ? nil : .spring(duration: 0.3), value: page)
            }
        }
        .padding(.bottom, 20)
        .accessibilityHidden(true)
    }

    private var controls: some View {
        VStack(spacing: 12) {
            Button {
                Haptics.tap()
                if page < pages.count - 1 {
                    withAnimation(reduceMotion ? nil : .easeInOut) { page += 1 }
                } else {
                    onFinish()
                }
            } label: {
                Text(page < pages.count - 1 ? "Continue" : "Start planning")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Theme.terracotta, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .foregroundStyle(.white)
            }
            if page < pages.count - 1 {
                Button("Skip") { onFinish() }
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText)
            }
        }
    }
}

#Preview {
    OnboardingView(onFinish: {})
}
