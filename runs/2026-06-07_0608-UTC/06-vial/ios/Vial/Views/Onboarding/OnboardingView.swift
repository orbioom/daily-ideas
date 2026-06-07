import SwiftUI

struct OnboardingView: View {
    var onFinish: () -> Void
    @State private var page = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private struct Panel { let icon: String; let title: String; let body: String }
    private let panels = [
        Panel(icon: "checklist", title: "Today, at a glance",
              body: "See every dose due today and tick it off. Vial keeps a clear record of what you've taken."),
        Panel(icon: "shippingbox", title: "Never run out",
              body: "Vial counts your supply down with each dose and tells you the day to reorder each prescription."),
        Panel(icon: "chart.bar.xaxis", title: "See your adherence",
              body: "Track how consistently you take each medication over time — all stored privately on your device.")
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(panels.indices, id: \.self) { i in
                    VStack(spacing: 22) {
                        Spacer()
                        Image(systemName: panels[i].icon)
                            .font(.system(size: 64, weight: .light))
                            .foregroundStyle(Brand.inkGradient).accessibilityHidden(true)
                        Text(panels[i].title).font(.largeTitle.weight(.bold))
                            .foregroundStyle(Brand.text).multilineTextAlignment(.center)
                        Text(panels[i].body).font(.body).foregroundStyle(Brand.text2)
                            .multilineTextAlignment(.center).padding(.horizontal, 32)
                        Spacer()
                        Text("Vial is a personal tracker, not medical advice.")
                            .font(.caption2).foregroundStyle(Brand.text3)
                        Spacer()
                    }
                    .tag(i).padding()
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .animation(reduceMotion ? nil : Brand.ease(), value: page)

            VStack(spacing: 12) {
                Button(page < panels.count - 1 ? "Continue" : "Get started") {
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
