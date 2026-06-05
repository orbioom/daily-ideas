import SwiftUI

/// A calm, single-screen first-run experience. Shown once, gated by a persisted flag.
struct OnboardingView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    private let points: [(icon: String, title: String, body: String)] = [
        ("square.grid.2x2.fill", "Keep a cellar",
         "Gather the coffees, wines, whiskies, teas and beers worth remembering."),
        ("text.aligned.left", "Taste with structure",
         "Aroma, palate, finish — plus the flavors you noticed and a rating you'll trust later."),
        ("chart.bar.fill", "Watch your palate grow",
         "Insights surface your favorites, your streak, and the flavors you reach for.")
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 24)

            VStack(spacing: 10) {
                Image(systemName: "wineglass")
                    .font(.system(size: 52, weight: .light))
                    .foregroundStyle(Brand.text)
                Text("Cellar")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(Brand.text)
                Text("A tasting journal you'll keep coming back to.")
                    .font(.headline.weight(.regular))
                    .foregroundStyle(Brand.text2)
                    .multilineTextAlignment(.center)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 12)

            Spacer(minLength: 28)

            VStack(spacing: 14) {
                ForEach(Array(points.enumerated()), id: \.offset) { idx, point in
                    GlassCard {
                        HStack(spacing: 14) {
                            Image(systemName: point.icon)
                                .font(.title2)
                                .foregroundStyle(Brand.text)
                                .frame(width: 34)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(point.title)
                                    .font(.headline)
                                    .foregroundStyle(Brand.text)
                                Text(point.body)
                                    .font(.subheadline)
                                    .foregroundStyle(Brand.text2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer(minLength: 0)
                        }
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 16)
                    .animation(reduceMotion ? nil : Brand.ease(0.5).delay(0.08 * Double(idx + 1)),
                               value: appeared)
                }
            }
            .padding(.horizontal, 20)

            Spacer(minLength: 28)

            InkButton(title: "Open the cellar", systemImage: "arrow.right") {
                settings.hasOnboarded = true
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
            .accessibilityHint("Dismisses this introduction and opens your cellar")
        }
        .onAppear {
            if reduceMotion { appeared = true }
            else { withAnimation(Brand.ease(0.6)) { appeared = true } }
        }
    }
}
