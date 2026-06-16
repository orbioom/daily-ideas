import SwiftUI
import SwiftData

struct RewardsView: View {
    let selectedProfile: Profile?
    @EnvironmentObject private var settings: AppSettings
    @State private var showSwitcher = false
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ScrollView {
                if let profile = selectedProfile {
                    content(profile)
                } else {
                    EmptyStateView(symbol: "rosette",
                                   title: "No rewards yet",
                                   message: "Add a child and start practicing to earn badges and unlock levels.")
                        .padding(.top, 60)
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Rewards")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ProfileChip(profile: selectedProfile) { showSwitcher = true }
                }
            }
            .sheet(isPresented: $showSwitcher) { ProfileSwitcherSheet() }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    @ViewBuilder
    private func content(_ profile: Profile) -> some View {
        let badges = BadgeEngine.badges(facts: profile.facts, sessions: profile.sessions)
        let earned = BadgeEngine.earnedCount(badges)
        let visibleBadges = settings.isPro ? badges : Array(badges.prefix(4))

        VStack(spacing: 18) {
            Card {
                HStack(spacing: 14) {
                    Text("🏅").font(.system(size: 40))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(earned) of \(badges.count) badges")
                            .font(Theme.rounded(22, .bold))
                            .foregroundStyle(Theme.ink)
                        Text("Keep practicing to earn them all!")
                            .font(Theme.rounded(14))
                            .foregroundStyle(Theme.inkSoft)
                    }
                    Spacer()
                }
            }
            .padding(.horizontal, 16)

            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Badges")
                badgeGrid(visibleBadges)
                if !settings.isPro && badges.count > visibleBadges.count {
                    proBadgesNote
                }
            }
            .padding(.horizontal, 16)

            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Level map", caption: "Unlock levels by mastering facts")
                LevelMapView(profile: profile, onLockedTap: { showPaywall = true })
            }
            .padding(.horizontal, 16)

            Spacer(minLength: 24)
        }
        .padding(.top, 8)
    }

    private func badgeGrid(_ badges: [Badge]) -> some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)
        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(badges) { badge in
                BadgeCell(badge: badge)
            }
        }
    }

    private var proBadgesNote: some View {
        Button { showPaywall = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "lock.fill")
                Text("More badges with Digit Pro")
                    .font(Theme.rounded(14, .semibold))
                Spacer()
                Image(systemName: "chevron.right").font(Theme.rounded(12, .bold))
            }
            .foregroundStyle(Theme.accent)
            .padding(14)
            .background(Theme.accent.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: Theme.rSmall, style: .continuous))
        }
    }
}

private struct BadgeCell: View {
    let badge: Badge
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 8) {
            Text(badge.emoji)
                .font(.system(size: 40))
                .grayscale(badge.earned ? 0 : 1)
                .opacity(badge.earned ? 1 : 0.5)
                .accessibilityHidden(true)
            Text(badge.title)
                .font(Theme.rounded(15, .bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Text(badge.detail)
                .font(Theme.rounded(12))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if badge.earned {
                Text("Earned")
                    .font(Theme.rounded(12, .bold))
                    .foregroundStyle(Theme.good)
            } else {
                ProgressView(value: badge.progress)
                    .tint(Theme.accent)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .frame(minHeight: 170)
        .background(badge.earned ? Theme.accent.opacity(0.08) : Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.rMedium, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Theme.rMedium, style: .continuous)
            .stroke(badge.earned ? Theme.accent.opacity(0.5) : Theme.hairline, lineWidth: 1))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(badge.title). \(badge.detail). \(badge.earned ? "Earned" : "Progress \(Int(badge.progress * 100)) percent")")
    }
}
