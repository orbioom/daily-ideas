import SwiftUI
import SwiftData

struct DailyView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("isPro") private var isPro = false
    @Query(sort: \DailyResult.date, order: .reverse) private var results: [DailyResult]

    @State private var activeConfig: GameConfig? = nil
    @State private var showPaywall = false

    private var todayKey: String { DailySeed.key(for: .now) }
    private var todaysResult: DailyResult? {
        results.first { $0.dayKey == todayKey }
    }

    private var archive: [DailyResult] {
        results.filter { $0.dayKey != todayKey }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    todayCard
                    archiveSection
                }
                .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Daily")
            .fullScreenCover(item: $activeConfig) { config in
                GameView(config: config)
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private var todayCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Today's challenge")
                        .font(Theme.rounded(14, .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                    Text(longDate(.now))
                        .font(Theme.rounded(22, .bold))
                        .foregroundStyle(.white)
                }
                Spacer()
                Image(systemName: "calendar")
                    .font(.system(size: 34))
                    .foregroundStyle(.white.opacity(0.95))
                    .accessibilityHidden(true)
            }

            Text("Everyone plays the exact same dice today. One run, your best score.")
                .font(Theme.rounded(14))
                .foregroundStyle(.white.opacity(0.92))
                .fixedSize(horizontal: false, vertical: true)

            if let result = todaysResult {
                HStack(spacing: 10) {
                    badge(icon: "checkmark.seal.fill", text: "Played", value: "\(result.score)")
                    if result.yahtzees > 0 {
                        badge(icon: "star.fill", text: "Yahtzees", value: "\(result.yahtzees)")
                    }
                }
                Button {
                    startDaily()
                } label: {
                    Text("Try again — keep your best")
                        .font(Theme.rounded(15, .bold))
                        .foregroundStyle(Theme.accentDeep)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(.white, in: RoundedRectangle(cornerRadius: Theme.rCard, style: .continuous))
                }
            } else {
                Button {
                    startDaily()
                } label: {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Play today's Daily")
                    }
                    .font(Theme.rounded(17, .bold))
                    .foregroundStyle(Theme.accentDeep)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(.white, in: RoundedRectangle(cornerRadius: Theme.rCard, style: .continuous))
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: Theme.rLarge, style: .continuous)
                .fill(Theme.feltGradient)
        )
    }

    private func badge(icon: String, text: String, value: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(text).font(Theme.rounded(13, .medium))
            Text(value).font(Theme.rounded(15, .bold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(.white.opacity(0.18), in: Capsule())
    }

    @ViewBuilder
    private var archiveSection: some View {
        HStack {
            SectionHeader(title: "Archive", subtitle: "Your past Daily runs")
            Spacer()
            if !isPro { ProLockBadge() }
        }

        if !isPro {
            VStack(spacing: 10) {
                EmptyStateView(
                    icon: "lock.fill",
                    title: "Daily archive is a Pro feature",
                    message: "Unlock Pip Pro to revisit and compare every past Daily run.",
                    actionTitle: "Unlock Pro",
                    action: { showPaywall = true }
                )
            }
            .card()
        } else if archive.isEmpty {
            EmptyStateView(
                icon: "calendar.badge.clock",
                title: "No past runs yet",
                message: "Play a few Dailies and they'll collect here."
            )
            .card()
        } else {
            VStack(spacing: 0) {
                ForEach(Array(archive.enumerated()), id: \.element.dayKey) { idx, result in
                    if idx > 0 { Divider().background(Theme.hairline) }
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundStyle(Theme.accent)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(longDate(result.date))
                                .font(Theme.rounded(15, .semibold))
                                .foregroundStyle(Theme.ink)
                            if result.yahtzees > 0 {
                                Text("\(result.yahtzees) Yahtzee\(result.yahtzees > 1 ? "s" : "")")
                                    .font(Theme.rounded(12))
                                    .foregroundStyle(Theme.inkSoft)
                            }
                        }
                        Spacer()
                        Text("\(result.score)")
                            .font(Theme.rounded(18, .bold))
                            .foregroundStyle(Theme.accent)
                    }
                    .padding(.vertical, 12).padding(.horizontal, 14)
                    .accessibilityElement(children: .combine)
                }
            }
            .card()
        }
    }

    private func startDaily() {
        activeConfig = .daily(name: "You", date: .now)
    }

    private func longDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f.string(from: date)
    }
}
