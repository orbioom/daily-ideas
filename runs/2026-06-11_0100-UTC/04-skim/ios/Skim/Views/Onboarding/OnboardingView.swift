import SwiftUI

struct OnboardingView: View {
    @AppStorage("skim.onboardingDone") private var done = false
    @State private var page = 0

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                pageContent(
                    icon: "eye.fill", color: SkimTheme.accent,
                    title: "Skim", subtitle: "Read at the speed of thought",
                    body: "RSVP reading flashes one word at a time — your eyes stop scanning and start absorbing."
                ).tag(0)
                pageContent(
                    icon: "gauge.with.dots.needle.67percent", color: .orange,
                    title: "Choose Your Speed",
                    subtitle: "From 150 to 1000 WPM",
                    body: "Start slow, build up. Most readers double their speed in a week without losing comprehension."
                ).tag(1)
                pageContent(
                    icon: "books.vertical.fill", color: .green,
                    title: "Your Reading Library",
                    subtitle: "Paste any text",
                    body: "Copy articles, essays, or book excerpts. Skim keeps your position so you can continue anytime."
                ).tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            Button {
                if page < 2 { withAnimation { page += 1 } }
                else { done = true }
            } label: {
                Text(page < 2 ? "Next" : "Start Reading")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(SkimTheme.accent)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 28)
            .padding(.bottom, 40)
        }
    }

    private func pageContent(icon: String, color: Color, title: String, subtitle: String, body: String) -> some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 72))
                .foregroundStyle(color)
                .accessibilityHidden(true)
            VStack(spacing: 6) {
                Text(title).font(.system(size: 36, weight: .black, design: .rounded))
                Text(subtitle).font(.system(size: 18, weight: .semibold)).foregroundStyle(color)
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
