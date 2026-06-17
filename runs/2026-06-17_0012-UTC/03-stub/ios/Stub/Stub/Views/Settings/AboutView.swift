import SwiftUI

/// About screen with app identity and a quick feature recap.
struct AboutView: View {
    @Environment(\.colorScheme) private var scheme

    private let highlights: [String] = [
        "Live take-home estimate as you type",
        "Federal, state, Social Security & Medicare",
        "Pre-tax 401(k), HSA, premiums & more",
        "Breakdown donut and gross→net waterfall",
        "Save scenarios and compare offers"
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(spacing: 10) {
                    Image(systemName: "banknote.fill")
                        .font(.system(size: 54))
                        .foregroundStyle(StubTheme.green)
                        .accessibilityHidden(true)
                    Text("Stub")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(StubTheme.primaryText(scheme))
                    Text("Take-home paycheck calculator & offer comparator")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(StubTheme.secondaryText(scheme))
                }
                .padding(.top, 12)

                StubCard {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(Array(highlights.enumerated()), id: \.offset) { _, line in
                            HStack(spacing: 10) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(StubTheme.green)
                                    .accessibilityHidden(true)
                                Text(line)
                                    .font(.subheadline)
                                    .foregroundStyle(StubTheme.primaryText(scheme))
                                Spacer()
                            }
                        }
                    }
                }

                Text("Version 1.0 • 2025 tax parameters\nEstimates only — not tax advice.")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(StubTheme.secondaryText(scheme))
            }
            .padding(16)
        }
        .background(StubTheme.appBackground(scheme).ignoresSafeArea())
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}
