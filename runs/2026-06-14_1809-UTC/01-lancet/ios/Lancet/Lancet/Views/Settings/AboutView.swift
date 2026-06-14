import SwiftUI

/// Honest "about" sheet — what Lancet is, and what it is not.
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 12) {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 34))
                            .foregroundStyle(Theme.accent)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Lancet")
                                .font(Theme.serif(26, .bold))
                                .foregroundStyle(Theme.ink)
                            Text("A private glucose & diabetes logbook")
                                .font(Theme.rounded(14))
                                .foregroundStyle(Theme.inkSoft)
                        }
                    }

                    paragraph("Lancet keeps a calm, beautiful record of your glucose readings. Log by context, see them in a classic logbook grid, and get the insights your care team cares about — estimated A1C, time-in-range, GMI and variability — all computed privately on this device.")

                    paragraph("There is no account and no subscription wall. Logging is always free and unlimited. A one-time Lancet Pro unlock adds the full Insights screen and CSV export.")

                    disclaimer

                    Text("Made for people who just want a logbook that respects them.")
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkFaint)
                        .padding(.top, 4)
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func paragraph(_ text: String) -> some View {
        Text(text)
            .font(Theme.rounded(15))
            .foregroundStyle(Theme.ink)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var disclaimer: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Not medical advice", systemImage: "cross.case.fill")
                .font(Theme.rounded(14, .bold))
                .foregroundStyle(Theme.accent)
            Text("Lancet is a tracking tool, not a medical device. Estimated A1C and GMI are statistical estimates from your logged averages — they are not lab results. Always work with your healthcare provider for treatment decisions.")
                .font(Theme.rounded(13))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.surfaceAlt))
    }
}
