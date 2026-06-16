import SwiftUI
import SwiftData
import Charts

struct ProgressDashboardView: View {
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
                    EmptyStateView(symbol: "chart.bar.xaxis",
                                   title: "No data yet",
                                   message: "Add a child and finish a practice round to see progress here.")
                        .padding(.top, 60)
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Progress")
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
        let sessions = profile.sessions
        let facts = profile.facts

        VStack(spacing: 18) {
            summaryCard(profile)
                .padding(.horizontal, 16)

            if facts.isEmpty {
                Card {
                    EmptyStateView(symbol: "sparkles",
                                   title: "Nothing practiced yet",
                                   message: "Once \(profile.name) plays a round, the mastery grid and charts will appear here.")
                }
                .padding(.horizontal, 16)
            } else if settings.isPro {
                fullAnalytics(profile, facts: facts, sessions: sessions)
            } else {
                basicAnalytics(profile, facts: facts)
                proUpsell
                    .padding(.horizontal, 16)
            }

            Spacer(minLength: 24)
        }
        .padding(.top, 8)
    }

    // MARK: Summary (free)

    private func summaryCard(_ profile: Profile) -> some View {
        let facts = profile.facts
        let mastered = ProgressEngine.totalMastered(facts: facts)
        let accuracy = ProgressEngine.overallAccuracy(facts: facts)
        let speed = ProgressEngine.avgSpeedSeconds(facts: facts)
        let stars = ProgressEngine.totalStars(sessions: profile.sessions)
        let streak = ProgressEngine.dayStreak(sessions: profile.sessions)

        return Card {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    Text(profile.avatarEmoji).font(.system(size: 40))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(profile.name)
                            .font(Theme.rounded(22, .bold))
                            .foregroundStyle(Theme.ink)
                        Text("\(mastered) facts mastered")
                            .font(Theme.rounded(14))
                            .foregroundStyle(Theme.inkSoft)
                    }
                    Spacer()
                }
                HStack(spacing: 10) {
                    StatPill(symbol: "checkmark.seal.fill",
                             value: "\(Int((accuracy * 100).rounded()))%", label: "Accuracy", tint: Theme.good)
                    StatPill(symbol: "bolt.fill",
                             value: speed.map { String(format: "%.1fs", $0) } ?? "—",
                             label: "Avg speed", tint: Theme.opAdd)
                    StatPill(symbol: "star.fill", value: "\(stars)", label: "Stars", tint: Theme.starGold)
                    StatPill(symbol: "flame.fill", value: "\(streak)", label: "Streak", tint: Theme.bad)
                }
            }
        }
    }

    // MARK: Basic analytics (free)

    @ViewBuilder
    private func basicAnalytics(_ profile: Profile, facts: [FactStat]) -> some View {
        let ops = Array(profile.enabledOps).filter { $0.isFree }.sorted { $0.rawValue < $1.rawValue }
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Mastery by operation",
                          caption: "Addition & subtraction (free)")
            Card {
                VStack(spacing: 16) {
                    ForEach(ProgressEngine.opSummaries(facts: facts, ops: ops.isEmpty ? [.add] : ops)) { s in
                        MasteryBar(title: s.op.title, fraction: s.masteryFraction, tint: s.op.color,
                                   trailing: "\(s.masteredFacts)/\(s.totalFacts)")
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private var proUpsell: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "chart.xyaxis.line").foregroundStyle(Theme.accent)
                    Text("Unlock full analytics")
                        .font(Theme.rounded(18, .bold))
                        .foregroundStyle(Theme.ink)
                }
                Text("The mastery grid, accuracy & speed trends, the streak calendar and times-table progress come with Digit Pro.")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
                PrimaryButton(title: "See Digit Pro", systemImage: "sparkles") { showPaywall = true }
            }
        }
    }

    // MARK: Full analytics (Pro)

    @ViewBuilder
    private func fullAnalytics(_ profile: Profile, facts: [FactStat], sessions: [Session]) -> some View {
        let ops = Array(profile.enabledOps).sorted { $0.rawValue < $1.rawValue }

        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Mastery by operation")
                Card {
                    VStack(spacing: 16) {
                        ForEach(ProgressEngine.opSummaries(facts: facts, ops: ops.isEmpty ? [.add] : ops)) { s in
                            MasteryBar(title: s.op.title, fraction: s.masteryFraction, tint: s.op.color,
                                       trailing: "\(s.masteredFacts)/\(s.totalFacts)")
                        }
                    }
                }
            }
            .padding(.horizontal, 16)

            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Fact mastery grid",
                              caption: "Greener means stronger")
                MasteryGridSection(facts: facts, ops: ops)
                    .padding(.horizontal, 16)
            }

            AccuracyChartCard(sessions: sessions).padding(.horizontal, 16)
            SpeedChartCard(sessions: sessions).padding(.horizontal, 16)
            StarsChartCard(sessions: sessions).padding(.horizontal, 16)
            StreakCalendarCard(sessions: sessions).padding(.horizontal, 16)
        }
    }
}
