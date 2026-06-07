import SwiftUI

struct OnboardingView: View {
    var onFinish: () -> Void
    @State private var page = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private struct Panel: Identifiable {
        let id = UUID()
        let icon: String, eyebrow: String, title: String, body: String
    }

    private let panels: [Panel] = [
        .init(icon: "thermometer.medium", eyebrow: "Plateau",
              title: "Sous vide, solved by thickness",
              body: "Tell Plateau the food, its thickness, and your bath temperature. It works out exactly how long the core takes to heat — from the heat equation, not a guess."),
        .init(icon: "shield.lefthalf.filled", eyebrow: "Pasteurize",
              title: "Safe, not just warm",
              body: "For poultry and pork, Plateau adds the hold time needed to actually pasteurize at your temperature — using a real thermal-death-time model."),
        .init(icon: "timer", eyebrow: "Cook",
              title: "A timer that survives a relaunch",
              body: "Start a cook and Plateau counts it down even if you close the app, then keeps a log of everything you've made.")
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(Array(panels.enumerated()), id: \.offset) { idx, p in
                    VStack(spacing: 22) {
                        Spacer()
                        Image(systemName: p.icon).font(.system(size: 64, weight: .light))
                            .foregroundStyle(Brand.warn).accessibilityHidden(true)
                        VStack(spacing: 12) {
                            Eyebrow(text: p.eyebrow)
                            Text(p.title).font(.largeTitle.weight(.bold))
                                .foregroundStyle(Brand.text).multilineTextAlignment(.center)
                            Text(p.body).font(.body).foregroundStyle(Brand.text2)
                                .multilineTextAlignment(.center).padding(.horizontal, 8)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 28).tag(idx)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            VStack(spacing: 12) {
                Button(page < panels.count - 1 ? "Continue" : "Start cooking") {
                    Haptics.tap()
                    if page < panels.count - 1 {
                        withAnimation(reduceMotion ? nil : Brand.ease()) { page += 1 }
                    } else { onFinish() }
                }
                .buttonStyle(InkButtonStyle())
                if page < panels.count - 1 {
                    Button("Skip") { onFinish() }.font(.subheadline).foregroundStyle(Brand.text3)
                }
            }
            .padding(.horizontal, 24).padding(.bottom, 28)
        }
        .background(Brand.pageBackground)
    }
}
