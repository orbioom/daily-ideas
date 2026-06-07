import SwiftUI

struct OnboardingView: View {
    var onFinish: () -> Void
    @State private var page = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private struct Panel { let icon: String; let title: String; let body: String }
    private let panels = [
        Panel(icon: "wallet.pass", title: "Every account, one place",
              body: "Add your assets and debts. Ledger nets them into a single number you actually own — and keeps it all on your device."),
        Panel(icon: "chart.xyaxis.line", title: "Watch it grow",
              body: "Take a snapshot whenever you like. Ledger plots your net worth over time so progress is impossible to miss."),
        Panel(icon: "chart.pie", title: "Stay in balance",
              body: "Set target weights for each asset class. Ledger shows your drift and the exact moves to get back on plan.")
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
                Button(page < panels.count - 1 ? "Continue" : "See my net worth") {
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
