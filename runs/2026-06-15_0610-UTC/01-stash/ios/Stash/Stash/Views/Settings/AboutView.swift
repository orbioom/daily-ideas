import SwiftUI

/// About sheet: what Stash is, the privacy stance, and the supported formats.
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    private let formats = BarcodeFormat.allCases

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 10) {
                        Image(systemName: "wallet.pass.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(Theme.accent)
                            .accessibilityHidden(true)
                        Text("Stash")
                            .font(Theme.rounded(28, .bold))
                            .foregroundStyle(Theme.ink)
                        Text("Your loyalty & gift cards, kept private and always ready at checkout.")
                            .font(Theme.rounded(15))
                            .foregroundStyle(Theme.inkSoft)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 8)

                    CardSurface {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Private by design", symbol: "lock.shield")
                            aboutLine("No account, ever — nothing to sign up for.")
                            aboutLine("No ads and no tracking.")
                            aboutLine("Cards are stored only on this device.")
                            aboutLine("Pro is a one-time unlock, not a subscription.")
                        }
                    }

                    CardSurface {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Supported formats", symbol: "barcode")
                            ForEach(formats) { f in
                                HStack {
                                    Text(f.displayName)
                                        .font(Theme.rounded(15, .medium))
                                        .foregroundStyle(Theme.ink)
                                    Spacer()
                                    Text(f.isLinear ? "Linear" : "2-D")
                                        .font(Theme.rounded(12, .medium))
                                        .foregroundStyle(Theme.inkSoft)
                                }
                                if f.id != formats.last?.id {
                                    Divider().background(Theme.hairline)
                                }
                            }
                        }
                    }

                    Text("Barcodes are rendered entirely on-device. EAN-13 / UPC-A are encoded by a hand-rolled renderer with full check-digit validation.")
                        .font(Theme.rounded(12))
                        .foregroundStyle(Theme.inkFaint)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
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

    private func aboutLine(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 15))
                .foregroundStyle(Theme.good)
                .accessibilityHidden(true)
            Text(text)
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
    }
}
