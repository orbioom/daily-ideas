import SwiftUI

/// Simulated one-time Stub Pro purchase. Sets the persisted `isPro` flag.
/// No real StoreKit calls — StoreKit-ready in spirit.
struct PaywallView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss
    @Environment(AppPreferences.self) private var prefs
    @AppStorage("isPro") private var isPro = false

    private let price = "$4.99"

    private let features: [(String, String)] = [
        ("infinity", "Unlimited saved scenarios"),
        ("rectangle.split.3x1", "Compare up to 3 offers at once"),
        ("chart.bar.doc.horizontal", "All-state breakdown detail"),
        ("calendar", "Multi pay-frequency comparison"),
        ("square.and.arrow.up", "Export scenarios to CSV")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    VStack(spacing: 10) {
                        Image(systemName: "seal.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(StubTheme.green)
                            .accessibilityHidden(true)
                        Text("Stub Pro")
                            .font(.largeTitle.weight(.bold))
                            .foregroundStyle(StubTheme.primaryText(scheme))
                        Text("A one-time \(price) unlock — no subscription.")
                            .font(.subheadline)
                            .foregroundStyle(StubTheme.secondaryText(scheme))
                    }
                    .padding(.top, 12)

                    StubCard {
                        VStack(alignment: .leading, spacing: 14) {
                            ForEach(Array(features.enumerated()), id: \.offset) { _, item in
                                HStack(spacing: 12) {
                                    Image(systemName: item.0)
                                        .foregroundStyle(StubTheme.green)
                                        .frame(width: 26)
                                        .accessibilityHidden(true)
                                    Text(item.1)
                                        .font(.subheadline)
                                        .foregroundStyle(StubTheme.primaryText(scheme))
                                    Spacer()
                                }
                            }
                        }
                    }

                    if isPro {
                        Label("Pro is unlocked — thank you!", systemImage: "checkmark.seal.fill")
                            .font(.headline)
                            .foregroundStyle(StubTheme.green)
                            .padding(.vertical, 8)
                    } else {
                        VStack(spacing: 10) {
                            Button {
                                unlock()
                            } label: {
                                Text("Unlock Pro — \(price)")
                            }
                            .buttonStyle(StubPrimaryButtonStyle())

                            Button("Restore purchase") { unlock() }
                                .buttonStyle(StubSecondaryButtonStyle())
                        }
                    }

                    Text("Demo build: “Unlock” and “Restore” both enable Pro locally. Core paycheck calculation is always free.")
                        .font(.caption2)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(StubTheme.secondaryText(scheme))
                }
                .padding(20)
            }
            .background(StubTheme.appBackground(scheme).ignoresSafeArea())
            .navigationTitle("Go Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func unlock() {
        isPro = true
        Haptics.success(enabled: prefs.hapticsEnabled)
        dismiss()
    }
}
