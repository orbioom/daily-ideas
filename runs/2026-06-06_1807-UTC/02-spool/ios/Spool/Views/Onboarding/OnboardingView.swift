import SwiftUI

struct OnboardingView: View {
    var onFinish: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appear = false

    private let pages: [(icon: String, title: String, body: String)] = [
        ("circle.circle", "Track every spool",
         "Material, color, price, and grams remaining — Spool always knows what's left and warns you before you run dry."),
        ("cube", "Log your prints",
         "Pick a spool and printer, enter grams and time, and each job deducts filament and computes its true cost."),
        ("chart.pie", "See where it goes",
         "Filament used, money spent, cost by material, and a grams↔meters calculator — all on your device."),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(alignment: .leading, spacing: 26) {
                Eyebrow(text: "Spool")
                Text("Know your filament.")
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
