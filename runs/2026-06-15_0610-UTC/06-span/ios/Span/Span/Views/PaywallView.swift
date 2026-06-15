import SwiftUI

/// One-time Span Pro unlock sheet. Demo unlock sets isPro=true (StoreKit wires in
/// production). Restore is present with an honest note. No ads, ever.
struct PaywallView: View {
    let reason: PaywallReason
    @AppStorage("isPro") private var isPro = false
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @State private var showRestoreNote = false

    private let perks: [(String, String)] = [
        ("paintpalette.fill", "Unlimited chapters, milestones & goals"),
        ("swatchpalette.fill", "Premium color palettes & dot styles"),
        ("square.and.arrow.up.on.square.fill", "High-resolution life poster export")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    Image(systemName: reason.symbol)
                        .font(.system(size: 56))
                        .foregroundStyle(Theme.accent)
                        .padding(.top, 12)
                        .accessibilityHidden(true)

                    VStack(spacing: 8) {
                        Text(reason.title)
                            .font(Theme.serif(27, .bold))
                            .foregroundStyle(Theme.ink)
                            .multilineTextAlignment(.center)
                        Text(reason.blurb)
                            .font(Theme.rounded(16))
                            .foregroundStyle(Theme.inkSoft)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 8)

                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(perks, id: \.1) { perk in
                            HStack(spacing: 12) {
                                Image(systemName: perk.0)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(Theme.accent)
                                    .frame(width: 26)
                                    .accessibilityHidden(true)
                                Text(perk.1)
                                    .font(Theme.rounded(16))
                                    .foregroundStyle(Theme.ink)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer()
                            }
                        }
                    }
                    .padding(18)
                    .background(RoundedRectangle(cornerRadius: Theme.corner, style: .continuous).fill(Theme.surface))

                    VStack(spacing: 10) {
                        PrimaryButton(title: "Unlock Span Pro · \(Pro.priceLabel)",
                                      systemImage: "lock.open.fill") {
                            unlock()
                        }
                        Button("Restore Purchase") {
                            Haptics.select(settings.hapticsEnabled)
                            showRestoreNote = true
                        }
                        .font(Theme.rounded(15, .medium))
                        .foregroundStyle(Theme.inkSoft)
                    }

                    Text("Demo unlock for this build — StoreKit purchase wires in for production. One-time, no subscription. No ads, ever.")
                        .font(Theme.rounded(12))
                        .foregroundStyle(Theme.inkFaint)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)

                    if showRestoreNote {
                        Text("No previous purchase found on this device.")
                            .font(Theme.rounded(13))
                            .foregroundStyle(Theme.inkSoft)
                            .transition(.opacity)
                    }
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Span Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .animation(.easeInOut, value: showRestoreNote)
        }
    }

    private func unlock() {
        isPro = true
        Haptics.success(settings.hapticsEnabled)
        dismiss()
    }
}
