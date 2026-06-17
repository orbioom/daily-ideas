import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        ZStack {
                            Circle().fill(Theme.heroGradient).frame(width: 96, height: 96)
                                .shadow(color: Theme.accent.opacity(0.4), radius: 18, y: 6)
                            Image(systemName: "waveform")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundStyle(.white)
                                .accessibilityHidden(true)
                        }
                        .padding(.top, 24)

                        VStack(spacing: 6) {
                            Text("Thump")
                                .font(Theme.rounded(28, .heavy))
                                .foregroundStyle(Theme.ink)
                            Text("Version 1.0")
                                .font(Theme.rounded(14))
                                .foregroundStyle(Theme.inkSoft)
                        }

                        Text("A pocket groovebox. Tap out beats on the step grid, hear them through drum sounds synthesized entirely in code, save patterns and chain them into songs. Instant, offline, no ads — yours forever.")
                            .font(Theme.rounded(16))
                            .foregroundStyle(Theme.inkSoft)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 24)

                        PanelCard {
                            VStack(alignment: .leading, spacing: 10) {
                                aboutRow("waveform.path", "Code-synthesized drums", "Every sound is pure DSP — no audio files.")
                                Divider().overlay(Theme.hairline)
                                aboutRow("lock.shield.fill", "Private & offline", "Your patterns live on your device.")
                                Divider().overlay(Theme.hairline)
                                aboutRow("bolt.heart.fill", "No ads, no subscriptions", "One-time Pro unlock, that's it.")
                            }
                        }
                        .padding(.horizontal, 16)

                        Spacer(minLength: 24)
                    }
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func aboutRow(_ symbol: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .frame(width: 26)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(Theme.rounded(15, .bold)).foregroundStyle(Theme.ink)
                Text(detail).font(Theme.rounded(13)).foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
