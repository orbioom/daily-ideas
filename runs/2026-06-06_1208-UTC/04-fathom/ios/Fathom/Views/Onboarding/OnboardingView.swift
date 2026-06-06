import SwiftUI

struct OnboardingView: View {
    var onFinish: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appear = false

    private let pages: [(icon: String, title: String, body: String)] = [
        ("book", "A logbook that stays with you",
         "Record every dive — depth, time, gas, conditions — and keep your whole history on your phone, offline."),
        ("slider.horizontal.3", "Plan nitrox with confidence",
         "Get MOD, equivalent air depth, no-stop limits, and the best mix for a target depth in a tap."),
        ("chart.bar", "See your diving take shape",
         "Totals, depth ranges, and your real air consumption (SAC) computed from the dives you log."),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(alignment: .leading, spacing: 26) {
                Eyebrow(text: "Fathom")
                Text("Go down well-informed.")
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
                Text("Planning aid only — never a substitute for training, tables, or a dive computer.")
                    .font(.caption).foregroundStyle(Brand.text3)
            }
            .padding(28).glassCard(padding: 24).padding(.horizontal, 20)
            Spacer()
            Button("Dive in", action: onFinish)
                .buttonStyle(InkButtonStyle()).padding(.horizontal, 20).padding(.bottom, 24)
        }
        .onAppear { appear = true }
    }
}
