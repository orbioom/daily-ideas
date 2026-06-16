import SwiftUI

struct ToolsView: View {
    @AppStorage("isPro") private var isPro = false
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    DisclaimerBanner()

                    if isPro {
                        NavigationLink {
                            HighFreqFinderView()
                        } label: {
                            toolCard(icon: "arrow.up.right.circle",
                                     title: "High-frequency limit finder",
                                     detail: "Sweep upward to find the highest pitch you can still hear.")
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            TinnitusMatcherView()
                        } label: {
                            toolCard(icon: "waveform",
                                     title: "Tinnitus tone matcher",
                                     detail: "Dial a tone to match your ringing and save the frequency.")
                        }
                        .buttonStyle(.plain)
                    } else {
                        lockedCard(icon: "arrow.up.right.circle",
                                   title: "High-frequency limit finder",
                                   detail: "Find the highest pitch you can hear.")
                        lockedCard(icon: "waveform",
                                   title: "Tinnitus tone matcher",
                                   detail: "Match and save your tinnitus tone.")
                        Button { showPaywall = true } label: {
                            PrimaryButtonLabel(title: "Unlock all tools with Hark Pro")
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 28)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Tools")
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private func toolCard(icon: String, title: String, detail: String) -> some View {
        Card {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Theme.accentSoft).frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .font(Theme.rounded(20, .semibold))
                        .foregroundStyle(Theme.accent)
                }
                .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(Theme.rounded(16, .semibold))
                        .foregroundStyle(Theme.ink)
                    Text(detail)
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(Theme.inkSoft)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func lockedCard(icon: String, title: String, detail: String) -> some View {
        Button { showPaywall = true } label: {
            Card {
                HStack(spacing: 14) {
                    ZStack {
                        Circle().fill(Theme.surfaceAlt).frame(width: 48, height: 48)
                        Image(systemName: "lock.fill")
                            .font(Theme.rounded(18, .semibold))
                            .foregroundStyle(Theme.inkSoft)
                    }
                    .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(title)
                            .font(Theme.rounded(16, .semibold))
                            .foregroundStyle(Theme.ink)
                        Text(detail)
                            .font(Theme.rounded(13))
                            .foregroundStyle(Theme.inkSoft)
                    }
                    Spacer()
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint("Locked. Opens the Hark Pro upgrade screen.")
    }
}

/// Reusable primary-styled label (for use inside a custom Button).
struct PrimaryButtonLabel: View {
    let title: String
    var systemImage: String? = nil
    var body: some View {
        HStack(spacing: 10) {
            if let systemImage { Image(systemName: systemImage) }
            Text(title).font(Theme.rounded(17, .semibold))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .foregroundStyle(.white)
        .background(
            RoundedRectangle(cornerRadius: Theme.rButton, style: .continuous)
                .fill(Theme.heroGradient)
        )
    }
}
