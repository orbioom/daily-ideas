import SwiftUI

/// A calm About sheet: what Inkling is, how the correlations work, and the privacy stance.
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header

                    aboutCard(symbol: "sparkles",
                              title: "What it does",
                              body: "Inkling tracks your symptoms and lifestyle, then surfaces the correlations that actually move them — ranked, in plain English, so you can spend less time guessing.")

                    aboutCard(symbol: "function",
                              title: "How the math works",
                              body: "For every factor → outcome pair, Inkling computes Pearson's correlation across the days both were logged, same-day and (with Pro) next-day. It needs at least four shared days and flags low-confidence findings so thin data never over-claims.")

                    aboutCard(symbol: "lock.shield",
                              title: "Private by design",
                              body: "Everything stays on this device — no account, no upload. Your full history is free and unlimited, forever.")

                    aboutCard(symbol: "stethoscope",
                              title: "Not medical advice",
                              body: "Correlation isn't causation. Inkling helps you notice patterns to discuss with a clinician — it doesn't diagnose or treat.")
                }
                .padding(18)
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

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "drop.halffull")
                .font(.system(size: 48))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text("Inkling")
                .font(Theme.rounded(28, .bold))
                .foregroundStyle(Theme.ink)
            Text("Find what moves your symptoms.")
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private func aboutCard(symbol: String, title: String, body: String) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: 8) {
                Label(title, systemImage: symbol)
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.ink)
                Text(body)
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
