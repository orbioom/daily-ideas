import SwiftUI

struct OnboardingView: View {
    var onFinish: () -> Void
    @State private var page = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private struct Panel { let icon: String; let title: String; let body: String }
    private let panels = [
        Panel(icon: "lungs", title: "Tables built around you",
              body: "Enter your max breath-hold and Static generates proper CO₂ and O₂ tables — the right holds and rests, every round."),
        Panel(icon: "timer", title: "A calm, guided session",
              body: "Follow a quiet, full-screen timer through breathe-up, holds and recovery. Just breathe and watch the ring."),
        Panel(icon: "chart.xyaxis.line", title: "Track your best",
              body: "Every session is logged. Watch your personal best climb and your tolerance grow over the weeks.")
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
                Button(page < panels.count - 1 ? "Continue" : "Start training") {
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
        .overlay(alignment: .bottom) {
            Text("Always train dry apnea seated and never in water alone.")
                .font(.caption2).foregroundStyle(Brand.text3)
                .padding(.bottom, 96)
        }
    }
}
