import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @State private var page = 0

    private let pages: [(icon: String, title: String, message: String)] = [
        ("sunrise", "See your horizon",
         "Horizon turns four numbers — age, savings, contributions, spending — into the age your money sets you free."),
        ("sailboat", "Coast FIRE, made visible",
         "There's a point where you can stop saving entirely and still retire on time. Horizon shows exactly where it is and when you'll cross it."),
        ("slider.horizontal.3", "Race your futures",
         "Model saving more. Model retiring earlier. Compare the futures on one chart — all on-device, inflation-adjusted, no account."),
    ]

    var body: some View {
        ZStack {
            Theme.bgPrimary.ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, item in
                        VStack(spacing: 22) {
                            Image(systemName: item.icon)
                                .font(.system(size: 64, weight: .light))
                                .foregroundStyle(Theme.accent)
                                .accessibilityHidden(true)
                            Text(item.title)
                                .font(.system(.largeTitle, design: .serif, weight: .bold))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(Theme.textPrimary)
                            Text(item.message)
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(Theme.textSecondary)
                                .padding(.horizontal, 32)
                        }
                        .tag(index)
                        .padding(.bottom, 60)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                Button {
                    if page < pages.count - 1 {
                        withAnimation { page += 1 }
                    } else {
                        Haptics.success()
                        hasOnboarded = true
                    }
                } label: {
                    Text(page < pages.count - 1 ? "Continue" : "Chart my path")
                        .font(.headline)
                        .foregroundStyle(Color.black.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
                .accessibilityHint(page < pages.count - 1 ? "Shows the next page" : "Finishes onboarding")
            }
        }
    }
}
