import SwiftUI

/// First-run introduction, gated by the persisted `hasOnboarded` flag.
struct OnboardingView: View {
    var onFinish: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appear = false

    private let pages: [(icon: String, title: String, body: String)] = [
        ("square.stack.3d.up", "Every project, counted",
         "Keep each piece you're making with its own row and pattern-repeat counters — tap to count without losing your place."),
        ("circle.grid.2x2", "Know your stash",
         "Catalog your yarn with yardage and weight so you always know whether you have enough for the next cast-on."),
        ("ruler", "Gauge that does the math",
         "Turn a swatch into cast-on stitches, row counts, and a yardage estimate — no spreadsheet required."),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(alignment: .leading, spacing: 28) {
                Eyebrow(text: "Skein")
                Text("A calm companion for what's on your needles.")
                    .font(.system(.largeTitle, design: .default, weight: .semibold))
                    .foregroundStyle(Brand.text)
                VStack(alignment: .leading, spacing: 18) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { idx, page in
                        HStack(alignment: .top, spacing: 14) {
                            Image(systemName: page.icon)
                                .font(.title2)
                                .foregroundStyle(Brand.text)
                                .frame(width: 32)
                                .accessibilityHidden(true)
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
            .padding(28)
            .glassCard(padding: 24)
            .padding(.horizontal, 20)
            Spacer()
            Button("Start", action: onFinish)
                .buttonStyle(InkButtonStyle())
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                .accessibilityHint("Begins using Skein")
        }
        .onAppear { appear = true }
    }
}
