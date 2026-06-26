import SwiftUI

struct OnboardingView: View {
    @Binding var hasSeenOnboarding: Bool
    @State private var page = 0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.97, green: 0.96, blue: 0.98), Color(red: 0.93, green: 0.88, blue: 0.98)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            TabView(selection: $page) {
                OnboardPage(
                    icon: "paintbrush.fill",
                    iconColor: Color(red: 0.87, green: 0.33, blue: 0.53),
                    title: "Color by Number",
                    body: "Tap a color, then fill the matching cells. Watch the picture come alive!"
                ).tag(0)

                OnboardPage(
                    icon: "eye.fill",
                    iconColor: Color(red: 0.4, green: 0.2, blue: 0.8),
                    title: "20 Handcrafted Puzzles",
                    body: "Animals, nature, food, objects and patterns — each pixel lovingly designed. No ads, no timers."
                ).tag(1)

                OnboardPage(
                    icon: "heart.fill",
                    iconColor: Color(red: 0.87, green: 0.2, blue: 0.3),
                    title: "Relax & Unwind",
                    body: "Progress saves automatically. Pick up where you left off anytime. Pure calm creativity."
                ).tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            VStack {
                Spacer()
                Button(page < 2 ? "Next" : "Start Painting") {
                    if page < 2 { withAnimation { page += 1 } }
                    else { hasSeenOnboarding = true }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
    }
}

private struct OnboardPage: View {
    let icon: String
    let iconColor: Color
    let title: String
    let body: String

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 140, height: 140)
                Image(systemName: icon)
                    .font(.system(size: 64))
                    .foregroundStyle(iconColor)
                    .accessibilityHidden(true)
            }
            VStack(spacing: 12) {
                Text(title)
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                Text(body)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            Spacer()
            Spacer()
        }
    }
}
