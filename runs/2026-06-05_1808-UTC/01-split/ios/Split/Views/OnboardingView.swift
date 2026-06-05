import SwiftUI

/// A calm, single-screen first-run experience. Shown once, gated by a persisted flag.
struct OnboardingView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    private let points: [(icon: String, title: String, body: String)] = [
        ("person.2.fill", "Group your spending",
         "A trip, a flat, a dinner — gather the people and the costs in one calm place."),
        ("equal.circle", "Split it any way",
         "Equally, by exact amounts, or by shares. The preview always reconciles to the total."),
        ("arrow.left.arrow.right", "Settle with the fewest payments",
         "Split untangles who owes whom into the smallest set of transfers — then records them.")
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer(minLength: 24)

                VStack(spacing: 10) {
                    Image(systemName: "circle.lefthalf.filled")
                        .font(.system(size: 52, weight: .light))
                        .foregroundStyle(Brand.text)
                        .accessibilityHidden(true)
                    Text("Split")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(Brand.text)
                    Text("Shared spending, calmly settled.")
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
                                    .accessibilityHidden(true)
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

                InkButton(title: "Start splitting", systemImage: "arrow.right") {
                    settings.hasOnboarded = true
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                .accessibilityHint("Dismisses this introduction and opens your groups")
            }
            .frame(maxWidth: .infinity)
        }
        .onAppear {
            if reduceMotion { appeared = true }
            else { withAnimation(Brand.ease(0.6)) { appeared = true } }
        }
    }
}
