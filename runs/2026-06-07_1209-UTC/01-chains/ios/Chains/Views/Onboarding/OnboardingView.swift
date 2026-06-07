import SwiftUI

struct OnboardingView: View {
    var onFinish: () -> Void
    @State private var page = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private struct Panel { let icon: String; let title: String; let body: String }
    private let panels = [
        Panel(icon: "map", title: "Map your courses",
              body: "Build each layout once — hole pars and distances. Chains tracks the course's scoring baseline so it can rate your rounds."),
        Panel(icon: "flag.checkered", title: "Keep score, hole by hole",
              body: "Tap through a clean live scorecard. Strokes, putts and penalties roll up into your total and score to par."),
        Panel(icon: "chart.xyaxis.line", title: "See yourself improve",
              body: "Every round gets a rating estimate. Watch your trend climb, find your trouble holes, and chase a new best.")
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
                        Text(panels[i].title).font(.largeTitle.weight(.bold))
                            .foregroundStyle(Brand.text).multilineTextAlignment(.center)
                        Text(panels[i].body).font(.body).foregroundStyle(Brand.text2)
                            .multilineTextAlignment(.center).padding(.horizontal, 32)
                        Spacer(); Spacer()
                    }
                    .tag(i).padding()
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .animation(reduceMotion ? nil : Brand.ease(), value: page)

            VStack(spacing: 12) {
                Button(page < panels.count - 1 ? "Continue" : "Step up to the tee") {
                    if page < panels.count - 1 {
                        withAnimation(reduceMotion ? nil : Brand.ease()) { page += 1 }
                    } else { Haptics.success(); onFinish() }
                }
                .buttonStyle(InkButtonStyle())
                if page < panels.count - 1 {
                    Button("Skip") { Haptics.success(); onFinish() }.buttonStyle(GlassButtonStyle())
                }
            }
            .padding(.horizontal, 24).padding(.bottom, 28)
        }
        .background(Brand.pageBackground)
    }
}
