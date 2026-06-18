import SwiftUI

/// Hub tab linking to How to Play, Settings, and Pro.
struct MoreView: View {
    @EnvironmentObject private var pro: ProStore
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 18) {
                        if !pro.isPro {
                            proBanner
                        } else {
                            proActiveCard
                        }

                        SectionCard(padding: 6) {
                            VStack(spacing: 0) {
                                navRow(symbol: "questionmark.circle.fill", title: "How to Play", destination: AnyView(HowToPlayView()))
                                divider
                                navRow(symbol: "gearshape.fill", title: "Settings", destination: AnyView(SettingsView()))
                            }
                        }
                    }
                    .padding(18)
                }
            }
            .navigationTitle("More")
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private var proBanner: some View {
        Button {
            showPaywall = true
        } label: {
            SectionCard(padding: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(Theme.accent)
                            .accessibilityHidden(true)
                        Text("Pangram Pro")
                            .font(Theme.rounded(20, .heavy))
                            .foregroundStyle(Theme.ink)
                        Spacer()
                    }
                    Text("Unlimited practice, the full archive, the hints page, and advanced stats.")
                        .font(Theme.rounded(14))
                        .foregroundStyle(Theme.inkSoft)
                    Text("Unlock — \(pro.priceLabel)")
                        .font(Theme.rounded(15, .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18).padding(.vertical, 10)
                        .background(Capsule().fill(Theme.accent))
                        .padding(.top, 4)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens the Pro upgrade screen")
    }

    private var proActiveCard: some View {
        SectionCard {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(Theme.good)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Pangram Pro active")
                        .font(Theme.rounded(17, .bold))
                        .foregroundStyle(Theme.ink)
                    Text("Thanks for supporting the game.")
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkSoft)
                }
                Spacer()
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var divider: some View {
        Rectangle().fill(Theme.hairline).frame(height: 1).padding(.leading, 52)
    }

    private func navRow(symbol: String, title: String, destination: AnyView) -> some View {
        NavigationLink {
            destination
        } label: {
            HStack(spacing: 14) {
                Image(systemName: symbol)
                    .font(.system(size: 18))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 28)
                    .accessibilityHidden(true)
                Text(title)
                    .font(Theme.rounded(16, .medium))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.inkSoft)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }
}
