import SwiftUI

/// One-time purchase paywall for Pitch Pro. Simulated — "Unlock" / "Restore"
/// flip the persisted `@AppStorage("isPro")` entitlement. StoreKit-ready in
/// spirit; no real StoreKit calls.
struct PaywallView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss

    @AppStorage("isPro") private var isPro: Bool = false
    @AppStorage("hapticOnBeat") private var haptics: Bool = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    header

                    VStack(spacing: 12) {
                        ForEach(Array(ProInfo.features.enumerated()), id: \.offset) { _, f in
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(PitchTheme.indigo.opacity(0.14))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: f.icon)
                                        .font(.title3)
                                        .foregroundStyle(PitchTheme.indigo)
                                }
                                .accessibilityHidden(true)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(f.title)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(PitchTheme.primaryText(scheme))
                                    Text(f.detail)
                                        .font(.caption)
                                        .foregroundStyle(PitchTheme.secondaryText(scheme))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityElement(children: .combine)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(PitchTheme.cardSurface(scheme))
                    )

                    if isPro {
                        Label("Pitch Pro unlocked — thank you!", systemImage: "checkmark.seal.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(PitchTheme.inTune)
                            .padding(.vertical, 8)
                    } else {
                        VStack(spacing: 10) {
                            Button("Unlock Pitch Pro · \(ProInfo.priceDisplay)") {
                                isPro = true
                                Haptics.success(haptics)
                            }
                            .buttonStyle(PitchPrimaryButtonStyle())

                            Button("Restore purchase") {
                                isPro = true
                                Haptics.success(haptics)
                            }
                            .buttonStyle(PitchSecondaryButtonStyle())
                        }
                    }

                    Text("One-time purchase, no subscription. The tuner, metronome, and reference tones stay free forever.")
                        .font(.caption2)
                        .foregroundStyle(PitchTheme.secondaryText(scheme))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                }
                .padding(20)
            }
            .pitchScreenBackground(scheme)
            .navigationTitle("Pitch Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle().fill(PitchTheme.indigo.opacity(0.16)).frame(width: 88, height: 88)
                Image(systemName: "tuningfork")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(PitchTheme.indigo)
            }
            .accessibilityHidden(true)
            Text("Pitch Pro")
                .font(.title2.weight(.bold))
                .foregroundStyle(PitchTheme.primaryText(scheme))
            Text("Own every tool — custom tunings, advanced metering, and the full tone range.")
                .font(.subheadline)
                .foregroundStyle(PitchTheme.secondaryText(scheme))
                .multilineTextAlignment(.center)
        }
    }
}
