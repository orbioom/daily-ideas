import SwiftUI

struct OnboardingView: View {
    var onFinish: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appear = false

    private let pages: [(icon: String, title: String, body: String)] = [
        ("list.bullet.rectangle", "List your cuts",
         "Enter the parts you need and the stock you have. Kerf — the width your blade eats — is part of the math."),
        ("square.stack.3d.up", "Get an efficient layout",
         "Kerf packs your pieces onto the fewest boards and shows exactly what to cut from each one."),
        ("function", "Handy shop calculators",
         "Board feet, cost, and a quick one-off cut planner — for when you don't want to save a whole project."),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(alignment: .leading, spacing: 26) {
                Eyebrow(text: "Kerf")
                Text("Measure once. Cut well.")
                    .font(.system(.largeTitle, design: .default, weight: .semibold))
                    .foregroundStyle(Brand.text)
                VStack(alignment: .leading, spacing: 18) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { idx, page in
                        HStack(alignment: .top, spacing: 14) {
                            Image(systemName: page.icon).font(.title2).foregroundStyle(Brand.text)
                                .frame(width: 32).accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(page.title).font(.headline).foregroundStyle(Brand.text)
                                Text(page.body).font(.subheadline).foregroundStyle(Brand.text2)
                            }
                        }
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear || reduceMotion ? 0 : 16)
                        .animation(Brand.ease(0.5).delay(Double(idx) * 0.08), value: appear)
                    }
                }
            }
            .padding(28).glassCard(padding: 24).padding(.horizontal, 20)
            Spacer()
            Button("Start", action: onFinish)
                .buttonStyle(InkButtonStyle()).padding(.horizontal, 20).padding(.bottom, 24)
        }
        .onAppear { appear = true }
    }
}
