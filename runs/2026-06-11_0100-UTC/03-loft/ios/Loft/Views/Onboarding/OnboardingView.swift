import SwiftUI

struct OnboardingView: View {
    @AppStorage("loft.onboardingDone") private var done = false
    @State private var page = 0

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                page0.tag(0)
                page1.tag(1)
                page2.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            Button {
                if page < 2 { withAnimation { page += 1 } }
                else { done = true }
            } label: {
                Text(page < 2 ? "Next" : "Start Manifesting")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(hex: "#CC5DE8") ?? .purple)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 28)
            .padding(.bottom, 40)
        }
    }

    private var page0: some View {
        pageView(icon: "photo.on.rectangle.angled", color: Color(hex: "#CC5DE8") ?? .purple,
                 title: "Loft", subtitle: "Your vision. Your life.",
                 body: "Build beautiful vision boards with your own photos. See your dreams every day.")
    }

    private var page1: some View {
        pageView(icon: "target", color: Color(hex: "#5C7CFA") ?? .blue,
                 title: "Set Goals",
                 subtitle: "Turn vision into action",
                 body: "Add goals with target dates and break them into milestones. Track your progress.")
    }

    private var page2: some View {
        pageView(icon: "lock.shield.fill", color: Color(hex: "#51CF66") ?? .green,
                 title: "Private. Always.",
                 subtitle: "No cloud. No account.",
                 body: "Everything lives on your device. Your dreams are yours alone.")
    }

    private func pageView(icon: String, color: Color, title: String, subtitle: String, body: String) -> some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 72))
                .foregroundStyle(color)
                .accessibilityHidden(true)
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 36, weight: .black, design: .rounded))
                Text(subtitle)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(color)
            }
            Text(body)
                .font(.system(size: 16))
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)
            Spacer()
        }
    }
}
