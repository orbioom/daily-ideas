import SwiftUI

/// Three calm intro panels, then a focal call to action that seeds and enters.
struct OnboardingView: View {
    var onFinish: () -> Void
    @State private var page = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private struct Panel { let icon: String; let title: String; let body: String }
    private let panels = [
        Panel(icon: "flag.fill", title: "Your handicap, honestly",
              body: "Links computes your Handicap Index from your rounds using the World Handicap System — best 8 of your last 20."),
        Panel(icon: "square.grid.3x3.fill", title: "Hole-by-hole",
              body: "Log a full scorecard with putts, fairways and greens. Net double-bogey adjustment is handled for you."),
        Panel(icon: "chart.line.uptrend.xyaxis", title: "See it trend",
              body: "Watch your index, scoring average and best rounds move as you play. Everything stays on your phone.")
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(panels.indices, id: \.self) { i in
                    VStack(spacing: 22) {
                        Spacer()
                        Image(systemName: panels[i].icon)
                            .font(.system(size: 64, weight: .light))
                            .foregroundStyle(Brand.inkGradient)
                            .accessibilityHidden(true)
                        Text(panels[i].title)
                            .font(.largeTitle.weight(.bold))
                            .foregroundStyle(Brand.text)
                            .multilineTextAlignment(.center)
                        Text(panels[i].body)
                            .font(.body)
                            .foregroundStyle(Brand.text2)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        Spacer(); Spacer()
                    }
                    .tag(i)
                    .padding()
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .animation(reduceMotion ? nil : Brand.ease(), value: page)

            VStack(spacing: 12) {
                Button(page < panels.count - 1 ? "Continue" : "Start playing") {
                    if page < panels.count - 1 {
                        withAnimation(reduceMotion ? nil : Brand.ease()) { page += 1 }
                    } else {
                        Haptics.success(); onFinish()
                    }
                }
                .buttonStyle(InkButtonStyle())
                if page < panels.count - 1 {
                    Button("Skip") { Haptics.success(); onFinish() }
                        .buttonStyle(GlassButtonStyle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
        .background(Brand.pageBackground)
    }
}
