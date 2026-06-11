import SwiftUI

struct OnboardingView: View {
    @AppStorage("weave.onboardingDone") private var done = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            Image(systemName: "square.grid.2x2.fill")
                .font(.system(size: 64))
                .foregroundStyle(
                    LinearGradient(colors: [WeaveTheme.yellow, WeaveTheme.purple],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .padding(.bottom, 24)

            Text("Weave")
                .font(.system(size: 40, weight: .black, design: .rounded))
                .padding(.bottom, 8)
            Text("Find the hidden threads")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .padding(.bottom, 40)

            VStack(alignment: .leading, spacing: 20) {
                OnboardingRow(icon: "square.grid.3x2",
                              title: "16 words, 4 groups",
                              body: "Each puzzle has 4 secret categories of exactly 4 words each.")
                OnboardingRow(icon: "hand.tap",
                              title: "Tap to select",
                              body: "Select 4 words you think share a theme, then tap Submit.")
                OnboardingRow(icon: "exclamationmark.circle",
                              title: "You have 4 mistakes",
                              body: "Wrong guesses cost a life. Use all 4 and you'll see the answers.")
                OnboardingRow(icon: "chart.bar",
                              title: "Difficulty by color",
                              body: "Yellow is easiest, purple is trickiest. Watch out for red herrings!")
            }
            .padding(.horizontal, 28)

            Spacer()

            Button {
                done = true
            } label: {
                Text("Let's Play")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(WeaveTheme.purple)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 40)
        }
        .accessibilityLabel("Weave onboarding")
    }
}

private struct OnboardingRow: View {
    let icon: String
    let title: String
    let body: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(WeaveTheme.purple)
                .frame(width: 32)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 15, weight: .bold, design: .rounded))
                Text(body).font(.system(size: 14)).foregroundStyle(.secondary)
            }
        }
    }
}
