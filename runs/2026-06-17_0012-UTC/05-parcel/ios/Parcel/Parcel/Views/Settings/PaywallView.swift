import SwiftUI

/// One-time Pro unlock. StoreKit-ready in spirit; demo unlock + restore flip the flag.
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @Environment(AppPreferences.self) private var prefs

    private let features: [(String, String)] = [
        ("doc.text.magnifyingglass", "Unlimited full-length mock exams"),
        ("scope", "Adaptive drills that target your weak areas"),
        ("arrow.uturn.backward", "Review every missed & flagged question"),
        ("square.grid.2x2", "All ten topics, fully unlocked"),
        ("speaker.wave.2.fill", "Read-aloud audio for hands-free study"),
        ("chart.bar.fill", "Full progress analytics")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 10) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 54))
                            .foregroundStyle(Theme.gold)
                            .accessibilityHidden(true)
                        Text("Parcel Pro")
                            .font(Theme.largeTitle)
                            .foregroundStyle(Theme.textPrimary(scheme))
                        Text("Everything you need to pass — one purchase, no subscription.")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textSecondary(scheme))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 12)

                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(features, id: \.1) { item in
                            HStack(spacing: 12) {
                                Image(systemName: item.0)
                                    .foregroundStyle(Theme.accent)
                                    .frame(width: 28)
                                    .accessibilityHidden(true)
                                Text(item.1)
                                    .font(.subheadline)
                                    .foregroundStyle(Theme.textPrimary(scheme))
                                Spacer()
                            }
                        }
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardSurface()

                    if prefs.isPro {
                        Label("Pro is unlocked. Thank you!", systemImage: "checkmark.seal.fill")
                            .font(.headline)
                            .foregroundStyle(Theme.success(scheme))
                            .padding(.vertical, 8)
                    } else {
                        VStack(spacing: 10) {
                            Button {
                                prefs.isPro = true
                                Haptics.success(enabled: prefs.hapticsEnabled)
                            } label: {
                                VStack(spacing: 2) {
                                    Text("Unlock for $6.99").font(.headline)
                                    Text("One-time purchase").font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(PrimaryButtonStyle())

                            Button("Restore purchase") {
                                prefs.isPro = true
                            }
                            .font(.subheadline)
                            .foregroundStyle(Theme.accent)
                        }
                    }

                    Text("Demo build: the purchase is simulated locally and unlocks all Pro features.")
                        .font(.caption2)
                        .foregroundStyle(Theme.textSecondary(scheme))
                        .multilineTextAlignment(.center)
                }
                .padding(16)
            }
            .background(Theme.background(scheme).ignoresSafeArea())
            .navigationTitle("Go Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
