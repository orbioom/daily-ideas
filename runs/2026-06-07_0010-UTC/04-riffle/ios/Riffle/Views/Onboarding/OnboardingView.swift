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
        .init(icon: "ant", eyebrow: "Riffle",
              title: "Your fly box, organized",
              body: "Keep every pattern with its full tying recipe and how many you have left — so you know what to tie before the next trip."),
        .init(icon: "fish", eyebrow: "The log",
              title: "Remember every fish",
              body: "Log catches with water temp, weather, and the fly that worked. Riffle finds your confidence fly and the conditions that fish."),
        .init(icon: "calendar", eyebrow: "Hatches",
              title: "Match the hatch",
              body: "See what's emerging this month and which flies in your box match it by type and size — no guesswork at the water.")
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
                Button(page < panels.count - 1 ? "Continue" : "Tie one on") {
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
