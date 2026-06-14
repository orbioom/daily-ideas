import SwiftUI

struct PaywallView: View {
    let reason: PaywallReason
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @State private var showRestoreNote = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 22) {
                        ZStack {
                            Circle().fill(Theme.accent.opacity(0.16)).frame(width: 110, height: 110)
                            Image(systemName: "crown.fill").font(.system(size: 46)).foregroundStyle(Theme.accent)
                        }
                        .padding(.top, 16)
                        .accessibilityHidden(true)

                        VStack(spacing: 8) {
                            Text(reason.headline).font(Theme.serif(26, .bold))
                                .foregroundStyle(Theme.textPrimary).multilineTextAlignment(.center)
                            Text(reason.detail).font(Theme.rounded(15)).foregroundStyle(Theme.textSecondary)
                                .multilineTextAlignment(.center).padding(.horizontal, 24)
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(Pro.benefits, id: \.self) { b in
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.success)
                                    Text(b).font(Theme.rounded(15)).foregroundStyle(Theme.textPrimary)
                                    Spacer(minLength: 0)
                                }
                            }
                        }
                        .padding(18)
                        .background(RoundedRectangle(cornerRadius: Theme.cornerLarge).fill(Theme.surface))
                        .padding(.horizontal, 16)

                        VStack(spacing: 10) {
                            Button {
                                isPro = true
                                Haptics.success(settings.hapticsEnabled)
                                dismiss()
                            } label: {
                                Text("\(Pro.productTitle) — \(Pro.priceText)")
                                    .font(Theme.rounded(17, .semibold)).frame(maxWidth: .infinity).padding(.vertical, 14)
                            }
                            .buttonStyle(.borderedProminent)

                            Button("Restore Purchase") { showRestoreNote = true }
                                .font(Theme.rounded(15)).foregroundStyle(Theme.accent)

                            Text("One-time purchase. This is a demo build — “purchase” unlocks Pro locally with no real transaction.")
                                .font(Theme.rounded(12)).foregroundStyle(Theme.textSecondary)
                                .multilineTextAlignment(.center).padding(.horizontal, 24)
                        }
                        .padding(.horizontal, 16).padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Meeple Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
            }
            .alert("Restore", isPresented: $showRestoreNote) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("No previous purchase found in this demo build. Tap “Unlock Meeple Pro” to enable Pro features.")
            }
        }
    }
}
