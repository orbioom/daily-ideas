import SwiftUI

/// One-time Pro unlock sheet. Demo unlock sets isPro=true (StoreKit wires in production).
struct PaywallView: View {
    let reason: PaywallReason
    @AppStorage("isPro") private var isPro = false
    @Environment(AppSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss
    @State private var showRestoreNote = false

    private let perks: [(String, String)] = [
        ("flame.fill", "Run multiple live cooks at once"),
        ("fork.knife", "Unlimited custom rub recipes"),
        ("thermometer.high", "Chef doneness levels in the guide"),
        ("function", "Reverse-sear calculator"),
        ("square.and.arrow.up", "Export your cook log")
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
                            .font(Theme.rounded(26, .bold))
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
                                Spacer()
                            }
                        }
                    }
                    .searCard(padding: 18)

                    VStack(spacing: 10) {
                        PrimaryButton(title: "Unlock Sear Pro · \(Pro.priceLabel)",
                                      systemImage: "lock.open.fill") {
                            unlock()
                        }
                        Button("Restore Purchase") {
                            Haptics.tap(settings.hapticsEnabled)
                            showRestoreNote = true
                        }
                        .font(Theme.rounded(15, .medium))
                        .foregroundStyle(Theme.inkSoft)
                    }

                    Text("Demo unlock for this build — a real StoreKit purchase wires in for production. One-time, no subscription.")
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
            .navigationTitle("Sear Pro")
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
