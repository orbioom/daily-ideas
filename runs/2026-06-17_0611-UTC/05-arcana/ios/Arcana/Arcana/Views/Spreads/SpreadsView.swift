import SwiftUI

struct SpreadsView: View {
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @State private var paywall: PaywallReason?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        intro
                        ForEach(SpreadType.allCases) { spread in
                            spreadCard(spread)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Spreads")
            .sheet(item: $paywall) { reason in
                PaywallView(reason: reason)
            }
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionHeading(title: "Choose a Spread", icon: "rectangle.3.group")
            Text("Pick a layout, ask a question if you like, then draw. Save any reading to your journal.")
                .font(.callout).foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .cardSurface()
    }

    @ViewBuilder
    private func spreadCard(_ spread: SpreadType) -> some View {
        let locked = spread.isPro && !isPro
        Group {
            if locked {
                Button {
                    paywall = .advancedSpread(spread.rawValue)
                } label: {
                    spreadCardBody(spread, locked: true)
                }
                .buttonStyle(.plain)
            } else {
                NavigationLink {
                    ReadingFlowView(spread: spread)
                } label: {
                    spreadCardBody(spread, locked: false)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func spreadCardBody(_ spread: SpreadType, locked: Bool) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Theme.accentSoft)
                    .frame(width: 54, height: 54)
                Image(systemName: spread.icon)
                    .font(.system(size: 22))
                    .foregroundStyle(Theme.accentDeep)
            }
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(spread.rawValue)
                        .font(.headline)
                        .foregroundStyle(Theme.ink)
                    if spread.isPro { ProBadge() }
                }
                Text(spread.blurb)
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSoft)
                Text("\(spread.cardCount) card\(spread.cardCount == 1 ? "" : "s")")
                    .font(.caption).foregroundStyle(Theme.inkFaint)
            }
            Spacer()
            Image(systemName: locked ? "lock.fill" : "chevron.right")
                .foregroundStyle(locked ? Theme.gold : Theme.inkFaint)
        }
        .padding()
        .cardSurface()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(spread.rawValue), \(spread.cardCount) cards. \(spread.blurb)")
        .accessibilityHint(locked ? "Pro feature. Opens unlock screen." : "Opens this spread")
    }
}
