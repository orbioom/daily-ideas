import SwiftUI

struct OnboardingView: View {
    var onFinish: () -> Void
    @State private var page = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private struct Panel: Identifiable {
        let id = UUID()
        let icon: String
        let eyebrow: String
        let title: String
        let body: String
    }

    private let panels: [Panel] = [
        .init(icon: "target", eyebrow: "Oche",
              title: "Your throw line, kept honest",
              body: "Log matches leg by leg and Oche works out your three-dart average, checkout %, and best leg — the numbers that actually move."),
        .init(icon: "function", eyebrow: "Checkout",
              title: "Every finish, solved",
              body: "Enter any score from 2 to 170 and Oche finds the conventional route home — ending on a double, the way the maths really plays."),
        .init(icon: "scope", eyebrow: "Practice",
              title: "Find your nemesis double",
              body: "Throw at one double, log the hits, and watch which finish keeps letting you down — then drill it until it doesn't.")
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(Array(panels.enumerated()), id: \.offset) { idx, p in
                    VStack(spacing: 22) {
                        Spacer()
                        Image(systemName: p.icon)
                            .font(.system(size: 64, weight: .light))
                            .foregroundStyle(Brand.text)
                            .accessibilityHidden(true)
                        VStack(spacing: 12) {
                            Eyebrow(text: p.eyebrow)
                            Text(p.title)
                                .font(.largeTitle.weight(.bold))
                                .foregroundStyle(Brand.text)
                                .multilineTextAlignment(.center)
                            Text(p.body)
                                .font(.body)
                                .foregroundStyle(Brand.text2)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 8)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 28)
                    .tag(idx)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            VStack(spacing: 12) {
                Button(page < panels.count - 1 ? "Continue" : "Start throwing") {
                    Haptics.tap()
                    if page < panels.count - 1 {
                        withAnimation(reduceMotion ? nil : Brand.ease()) { page += 1 }
                    } else {
                        onFinish()
                    }
                }
                .buttonStyle(InkButtonStyle())

                if page < panels.count - 1 {
                    Button("Skip") { onFinish() }
                        .font(.subheadline)
                        .foregroundStyle(Brand.text3)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
        .background(Brand.pageBackground)
    }
}
