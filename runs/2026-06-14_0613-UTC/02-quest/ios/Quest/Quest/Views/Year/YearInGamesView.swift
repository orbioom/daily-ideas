import SwiftUI
import SwiftData

struct YearInGamesView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false

    @Query private var games: [Game]

    @State private var bundle: StatsBundle?
    @State private var isLoading = false
    @State private var showGoalEditor = false
    @State private var goalDraft = 12
    @State private var paywall: PaywallReason?

    private var challenge: YearChallenge {
        BacklogEngine.yearChallenge(games, goal: settings.yearChallengeGoal)
    }

    private var beatenThisYear: [Game] {
        BacklogEngine.beatenThisYear(games)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 18) {
                        challengeCard
                        beatenListCard
                        statsSection
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Year in Games")
            .sheet(item: $paywall) { reason in PaywallView(reason: reason) }
            .alert("Yearly goal", isPresented: $showGoalEditor) {
                TextField("Goal", value: $goalDraft, format: .number)
                    .keyboardType(.numberPad)
                Button("Save") { saveGoal() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("How many games do you want to beat in \(challenge.year)?")
            }
            .task(id: games.count) { await computeStats() }
            .onChange(of: isPro) { _, nowPro in
                if nowPro { Task { await computeStats() } }
            }
            .onAppear { goalDraft = settings.yearChallengeGoal }
        }
    }

    // MARK: Challenge

    private var challengeCard: some View {
        SectionCard(title: nil) {
            VStack(spacing: 16) {
                GoalRing(beaten: challenge.beaten, goal: max(1, settings.yearChallengeGoal))

                paceBadge

                HStack(spacing: 10) {
                    StatTile(value: "\(challenge.beaten)", label: "Beaten", color: Theme.success)
                    StatTile(value: "\(max(0, settings.yearChallengeGoal - challenge.beaten))",
                             label: "To go", color: Theme.accent)
                    StatTile(value: "\(challenge.projectedTotal)", label: "Projected", color: Theme.info)
                }

                Button {
                    goalDraft = settings.yearChallengeGoal
                    showGoalEditor = true
                } label: {
                    Label("Edit goal", systemImage: "target")
                        .font(Theme.rounded(14, .semibold))
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var paceBadge: some View {
        let onTrack = challenge.isOnTrack
        let delta = challenge.paceDelta
        let text: String
        if challenge.goal == 0 {
            text = "Set a goal to track your pace"
        } else if onTrack {
            text = delta > 0 ? "On track — \(delta) ahead of pace" : "Right on pace"
        } else {
            text = "Behind by \(abs(delta)) to stay on pace"
        }
        return Label(text, systemImage: onTrack ? "checkmark.circle.fill" : "hare.fill")
            .font(Theme.rounded(14, .semibold))
            .foregroundStyle(onTrack ? Theme.success : Theme.warning)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background((onTrack ? Theme.success : Theme.warning).opacity(0.14), in: Capsule())
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Pace: \(text)")
    }

    // MARK: Beaten list

    private var beatenListCard: some View {
        SectionCard(title: "Beaten in \(challenge.year)", systemImage: "trophy.fill") {
            if beatenThisYear.isEmpty {
                Text("No games beaten yet this year. Move a game to Completed to start your streak.")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)
            } else {
                ForEach(beatenThisYear) { game in
                    HStack(spacing: 12) {
                        GameCover(title: game.title, initials: game.initials,
                                  hue: game.coverHue, style: settings.coverStyle)
                            .frame(width: 36, height: 48)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(game.title)
                                .font(Theme.rounded(14, .semibold))
                                .foregroundStyle(Theme.text)
                                .lineLimit(1)
                            if let dc = game.dateCompleted {
                                Text(dc.formatted(date: .abbreviated, time: .omitted))
                                    .font(Theme.rounded(12))
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        }
                        Spacer()
                        RatingBadge(rating: game.personalRating)
                    }
                    .padding(.vertical, 4)
                    .accessibilityElement(children: .combine)
                    if game.id != beatenThisYear.last?.id {
                        Divider().overlay(Theme.stroke)
                    }
                }
            }
        }
    }

    // MARK: Stats

    @ViewBuilder
    private var statsSection: some View {
        if !isPro {
            Button {
                paywall = .stats
            } label: {
                SectionCard(title: "Full Stats", systemImage: "lock.fill") {
                    Text("Unlock platform donuts, genre breakdowns, rating distribution and monthly trends with Quest Pro.")
                        .font(Theme.rounded(14))
                        .foregroundStyle(Theme.textSecondary)
                    Text("Unlock Quest Pro")
                        .font(Theme.rounded(14, .bold))
                        .foregroundStyle(Theme.accent)
                }
            }
            .buttonStyle(.plain)
        } else if isLoading || bundle == nil {
            SectionCard(title: "Stats", systemImage: "chart.bar.fill") {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Crunching your stats…")
                        .font(Theme.rounded(14))
                        .foregroundStyle(Theme.textSecondary)
                }
                .frame(maxWidth: .infinity, minHeight: 120)
                .accessibilityLabel("Computing stats")
            }
        } else if games.isEmpty {
            EmptyStateView(symbol: "chart.bar.xaxis",
                           title: "No stats yet",
                           message: "Add and play games to unlock charts of your year.")
        } else if let bundle {
            StatsView(bundle: bundle)
        }
    }

    // MARK: Compute (async, off the render pass)

    @MainActor
    private func computeStats() async {
        guard isPro else { return }
        isLoading = true
        // Snapshot plain values so the heavy folding doesn't touch SwiftData on a hop.
        let snapshot = games
        // Yield so the loading state renders before we compute.
        await Task.yield()
        let result = StatsBundle(
            monthly: BacklogEngine.monthlyStats(snapshot),
            platforms: BacklogEngine.platformStats(snapshot),
            genres: BacklogEngine.genreStats(snapshot),
            ratings: BacklogEngine.ratingDistribution(snapshot),
            totalHours: BacklogEngine.totalHoursLogged(snapshot)
        )
        bundle = result
        isLoading = false
    }

    private func saveGoal() {
        settings.yearChallengeGoal = max(1, min(999, goalDraft))
        Haptics.play(.success, enabled: settings.hapticsEnabled)
    }
}
