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
        .init(icon: "binoculars", eyebrow: "Zenith",
              title: "Your gear, your numbers",
              body: "Add your telescopes and eyepieces once. Zenith knows each one's focal ratio, resolving power, and how faint it can see."),
        .init(icon: "function", eyebrow: "Compute",
              title: "Every combination, solved",
              body: "Pick a scope and eyepiece and Zenith gives you magnification, true field of view, and exit pupil — with a read on whether it's the right power."),
        .init(icon: "moon.stars", eyebrow: "Tonight",
              title: "Know what to point at",
              body: "See the showpiece objects best placed this month, log what you observe, and build a record of every night under the stars.")
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(Array(panels.enumerated()), id: \.offset) { idx, p in
                    VStack(spacing: 22) {
                        Spacer()
                        Image(systemName: p.icon).font(.system(size: 64, weight: .light))
                            .foregroundStyle(Brand.info).accessibilityHidden(true)
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
                Button(page < panels.count - 1 ? "Continue" : "Open the dome") {
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
