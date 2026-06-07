import SwiftUI

struct OnboardingView: View {
    var onFinish: () -> Void
    @State private var page = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private struct Panel { let icon: String; let title: String; let body: String }
    private let panels = [
        Panel(icon: "shield.lefthalf.filled", title: "Run combat smoothly",
              body: "Build an encounter, roll initiative for everyone at once, and step through turns and rounds with the active fighter always in view."),
        Panel(icon: "heart.text.square", title: "Track HP and conditions",
              body: "Apply damage and healing with temp-HP soak, toggle conditions, and watch health bars at a glance."),
        Panel(icon: "dice", title: "Dice when you need them",
              body: "A fast roller for any expression like 2d6+3, plus advantage and disadvantage d20s — every roll kept in history.")
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
                Button(page < panels.count - 1 ? "Continue" : "Roll for initiative") {
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
