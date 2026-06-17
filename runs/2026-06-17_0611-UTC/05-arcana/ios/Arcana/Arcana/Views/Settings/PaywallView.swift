import SwiftUI

struct PaywallView: View {
    let reason: PaywallReason
    @AppStorage("isPro") private var isPro = false
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.heroGradient.ignoresSafeArea()
                Starfield(starCount: 90).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 22) {
                        VStack(spacing: 12) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 52))
                                .foregroundStyle(Theme.gold)
                                .shadow(color: Theme.gold.opacity(0.5), radius: 14)
                                .accessibilityHidden(true)
                            Text(reason.title)
                                .font(Theme.serif(28, .bold))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                            Text(reason.message)
                                .font(.body)
                                .foregroundStyle(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 16)

                        VStack(alignment: .leading, spacing: 14) {
                            ForEach(Pro.unlocks, id: \.self) { line in
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Theme.gold)
                                    Text(line)
                                        .font(.subheadline)
                                        .foregroundStyle(.white)
                                    Spacer(minLength: 0)
                                }
                            }
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: Theme.corner).fill(.white.opacity(0.12)))

                        VStack(spacing: 10) {
                            Text("One-time purchase · \(Pro.priceLabel)")
                                .font(.headline).foregroundStyle(.white)
                            Text("No subscription. No ads. No account.")
                                .font(.caption).foregroundStyle(.white.opacity(0.8))
                        }

                        Button {
                            unlock()
                        } label: {
                            Text(isPro ? "Pro Unlocked" : "Unlock \(Pro.productTitle) (demo)")
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                                .background(Capsule().fill(Theme.gold))
                                .foregroundStyle(Color(hex: 0x2A1B40))
                        }
                        .disabled(isPro)

                        Button("Restore purchase") {
                            unlock()
                        }
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))

                        Text("This is a demo unlock. A production build would complete a real one-time StoreKit purchase here.")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                    }
                    .padding()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.foregroundStyle(.white)
                }
            }
        }
    }

    private func unlock() {
        isPro = true
        Haptics.success(settings.hapticsEnabled)
        dismiss()
    }
}
