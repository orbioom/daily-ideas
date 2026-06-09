import SwiftUI

/// A calm, three-panel welcome shown until the user has been onboarded.
struct OnboardingView: View {
    @AppStorage("vesper.onboarded") private var onboarded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    private let panels: [Panel] = [
        Panel(icon: "moon.stars.fill",
              title: "Welcome to Vesper",
              message: "A quiet place to pray, reflect, and notice how prayers unfold over time."),
        Panel(icon: "book.closed.fill",
              title: "A reading each day",
              message: "Begin with a short scripture and a gentle prompt. Mark it read and jot a reflection."),
        Panel(icon: "checkmark.seal.fill",
              title: "Hold and release",
              message: "Keep a living list of prayers. Mark them answered, and watch grace add up.")
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(panels.indices, id: \.self) { i in
                    panelView(panels[i]).tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(reduceMotion ? nil : Brand.ease(), value: page)

            indicators

            VStack(spacing: 12) {
                Button(page < panels.count - 1 ? "Continue" : "Begin") {
                    Haptics.tap()
                    if page < panels.count - 1 {
                        withAnimation(reduceMotion ? nil : Brand.ease()) { page += 1 }
                    } else {
                        Haptics.success()
                        withAnimation(reduceMotion ? nil : Brand.ease()) { onboarded = true }
                    }
                }
                .buttonStyle(InkButtonStyle())

                if page < panels.count - 1 {
                    Button("Skip") {
                        Haptics.tap()
                        withAnimation(reduceMotion ? nil : Brand.ease()) { onboarded = true }
                    }
                    .font(.subheadline)
                    .foregroundStyle(Brand.text2)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    private func panelView(_ panel: Panel) -> some View {
        VStack(spacing: 22) {
            Spacer()
            Image(systemName: panel.icon)
                .font(.system(size: 68, weight: .light))
                .foregroundStyle(Brand.magic)
                .accessibilityHidden(true)
            VStack(spacing: 12) {
                Text(panel.title)
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(Brand.text)
                    .multilineTextAlignment(.center)
                Text(panel.message)
                    .font(.body)
                    .foregroundStyle(Brand.text2)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private var indicators: some View {
        HStack(spacing: 8) {
            ForEach(panels.indices, id: \.self) { i in
                Capsule()
                    .fill(i == page ? Brand.magic : Brand.hairline)
                    .frame(width: i == page ? 22 : 8, height: 8)
                    .animation(reduceMotion ? nil : Brand.ease(0.3), value: page)
            }
        }
        .padding(.bottom, 24)
        .accessibilityHidden(true)
    }

    private struct Panel {
        let icon: String
        let title: String
        let message: String
    }
}
