import SwiftUI
import SwiftData

struct DailyView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var pro: ProStore
    @Query(sort: \DailyResult.date, order: .reverse) private var results: [DailyResult]

    @State private var route: PlayConfig?
    @State private var showPaywall = false

    private var todayKey: String { Date().dayKey }
    private var todayResult: DailyResult? { results.first { $0.dayKey == todayKey } }
    private var archive: [DailyResult] { results.filter { $0.dayKey != todayKey } }

    var body: some View {
        NavigationStack {
            ZStack {
                ScreenBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        todayCard
                        archiveSection
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Daily")
            .navigationDestination(item: $route) { config in
                PlayView(config: config)
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private var todayCard: some View {
        GlintCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Image(systemName: "calendar.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Theme.accent)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Today's Challenge")
                            .font(Theme.rounded(18, .bold))
                            .foregroundStyle(Theme.ink)
                        Text(Date().formatted(date: .complete, time: .omitted))
                            .font(Theme.rounded(13))
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
                Text("One seeded board, 25 moves, one attempt. Reach 3000 points.")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)

                if let result = todayResult {
                    HStack(spacing: 10) {
                        Image(systemName: result.won ? "checkmark.seal.fill" : "flag.checkered")
                            .foregroundStyle(result.won ? Theme.good : Theme.warn)
                        Text(result.won ? "Cleared with \(result.score) pts" : "Scored \(result.score) pts")
                            .font(Theme.rounded(15, .semibold))
                            .foregroundStyle(Theme.ink)
                    }
                    Text("Come back tomorrow for a new board.")
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkSoft)
                } else {
                    PrimaryButton(title: "Play Today", systemImage: "play.fill") {
                        route = PlayConfig(mode: .daily, level: nil, seed: Date().daySeed, allowRestart: false)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var archiveSection: some View {
        Text("Archive")
            .font(Theme.rounded(20, .bold))
            .foregroundStyle(Theme.ink)
            .padding(.top, 4)

        if archive.isEmpty {
            GlintCard {
                EmptyStateView(
                    icon: "calendar.badge.clock",
                    title: "No past challenges yet",
                    message: "Play today's Daily and your results will collect here."
                )
            }
        } else {
            VStack(spacing: 10) {
                ForEach(archive) { result in
                    archiveRow(result)
                }
            }
        }
    }

    private func archiveRow(_ result: DailyResult) -> some View {
        HStack(spacing: 12) {
            Image(systemName: result.won ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(result.won ? Theme.good : Theme.inkSoft)
            VStack(alignment: .leading, spacing: 2) {
                Text(result.date.formatted(date: .abbreviated, time: .omitted))
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(Theme.ink)
                Text("\(result.score) pts · \(result.moves) moves")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
            }
            Spacer()
            if pro.isPro {
                Button {
                    route = PlayConfig(mode: .daily, level: nil, seed: result.date.daySeed, allowRestart: true)
                } label: {
                    Text("Replay")
                        .font(Theme.rounded(13, .bold))
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .background(Theme.accent.opacity(0.15))
                        .foregroundStyle(Theme.accent)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            } else {
                Button { showPaywall = true } label: {
                    Image(systemName: "crown.fill")
                        .foregroundStyle(Theme.gold)
                        .padding(8)
                        .background(Circle().fill(Theme.gold.opacity(0.15)))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Replay locked. Unlock with Pro.")
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: Theme.rMed).fill(Theme.surface)
            .overlay(RoundedRectangle(cornerRadius: Theme.rMed).stroke(Theme.hairline)))
        .accessibilityElement(children: .combine)
    }
}
