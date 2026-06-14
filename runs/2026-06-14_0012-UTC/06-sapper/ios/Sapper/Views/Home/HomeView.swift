import SwiftUI
import SwiftData

/// The main launchpad: difficulty picker, resume card, best times, daily card, Play CTA.
struct HomeView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("isPro") private var isPro = false
    @AppStorage("noGuessDefault") private var noGuessDefault = false

    @Query private var records: [GameRecord]
    @Query private var savedGames: [SavedGame]
    @Query private var dailyResults: [DailyResult]

    @State private var selected: Difficulty = .beginner
    @State private var path: [GameRoute] = []
    @State private var showCustomSheet = false
    @State private var showPaywall = false
    @State private var customConfig = BoardConfig(rows: 12, cols: 12, mines: 24)

    private var todayKey: String { Formatters.dayKey() }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 18) {
                    header
                    if let saved = savedGames.first {
                        resumeCard(saved)
                    }
                    difficultyPicker
                    if selected == .custom {
                        customSummary
                    }
                    noGuessRow
                    playButton
                    dailyCard
                    bestTimesCard
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Sapper")
            .navigationDestination(for: GameRoute.self) { route in
                GameContainerView(route: route)
            }
            .sheet(isPresented: $showCustomSheet) {
                CustomBoardSheet(config: $customConfig)
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Clear the field.")
                .font(Theme.rounded(15, .medium))
                .foregroundStyle(Theme.inkSoft)
            HStack {
                Text("Choose a difficulty")
                    .font(Theme.rounded(24, .bold))
                    .foregroundStyle(Theme.ink)
                Spacer()
                if isPro {
                    TagPill(text: "PRO", tint: Theme.good)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Resume

    private func resumeCard(_ saved: SavedGame) -> some View {
        Button {
            path.append(GameRoute.resume(saved))
        } label: {
            GlassCard {
                HStack(spacing: 14) {
                    ZStack {
                        Circle().fill(Theme.accentSoft).frame(width: 48, height: 48)
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(Theme.accent)
                    }
                    .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Resume game")
                            .font(Theme.rounded(17, .semibold))
                            .foregroundStyle(Theme.ink)
                        Text("\(saved.difficulty.title) · \(saved.rows)×\(saved.cols) · \(Formatters.clock(saved.elapsedSec))")
                            .font(Theme.rounded(14))
                            .foregroundStyle(Theme.inkSoft)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(Theme.inkFaint)
                        .accessibilityHidden(true)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint("Continue your in-progress game")
    }

    // MARK: - Difficulty picker

    private var difficultyPicker: some View {
        VStack(spacing: 10) {
            ForEach(Difficulty.allCases) { diff in
                difficultyRow(diff)
            }
        }
    }

    private func difficultyRow(_ diff: Difficulty) -> some View {
        Button {
            selected = diff
            if diff == .custom { showCustomSheet = true }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(selected == diff ? Theme.accent : Theme.surfaceAlt)
                        .frame(width: 44, height: 44)
                    Image(systemName: diff.systemImage)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(selected == diff ? Color.white : Theme.inkSoft)
                }
                .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(diff.title)
                        .font(Theme.rounded(17, .semibold))
                        .foregroundStyle(Theme.ink)
                    Text(diff == .custom && selected == .custom
                         ? "\(customConfig.rows)×\(customConfig.cols) · \(customConfig.mines) mines"
                         : diff.subtitle)
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkSoft)
                }
                Spacer()
                if selected == diff {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.accent)
                        .accessibilityHidden(true)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(selected == diff ? Theme.accent : Theme.hairline,
                                  lineWidth: selected == diff ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(selected == diff ? [.isSelected] : [])
    }

    private var customSummary: some View {
        Button {
            showCustomSheet = true
        } label: {
            HStack {
                Image(systemName: "slider.horizontal.3")
                Text("Edit custom board")
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(Theme.inkFaint)
            }
            .font(Theme.rounded(15, .medium))
            .foregroundStyle(Theme.accent)
            .padding(.horizontal, 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: - No-guess toggle (Pro)

    private var noGuessRow: some View {
        GlassCard(padding: 14) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundStyle(noGuessEnabled ? Theme.good : Theme.inkFaint)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("No-guess mode")
                        .font(Theme.rounded(16, .semibold))
                        .foregroundStyle(Theme.ink)
                    Text(isPro ? "Boards solvable by pure logic" : "A Sapper Pro feature")
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkSoft)
                }
                Spacer()
                if isPro {
                    Toggle("", isOn: $noGuessDefault)
                        .labelsHidden()
                        .tint(Theme.good)
                } else {
                    Button("Unlock") { showPaywall = true }
                        .font(Theme.rounded(14, .semibold))
                        .foregroundStyle(Theme.accent)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var noGuessEnabled: Bool { isPro && noGuessDefault }

    // MARK: - Play

    private var playButton: some View {
        PrimaryButton(title: "Play", systemImage: "play.fill") {
            startGame()
        }
    }

    private func startGame() {
        if selected == .custom {
            // Gate custom boards behind Pro.
            guard isPro else { showPaywall = true; return }
            path.append(GameRoute.standard(.custom, config: customConfig, noGuess: noGuessEnabled))
        } else {
            path.append(GameRoute.standard(selected, config: selected.preset, noGuess: noGuessEnabled))
        }
    }

    // MARK: - Daily card

    private var dailyCard: some View {
        let result = dailyResults.first { $0.dateKey == todayKey }
        return GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Daily Challenge", systemImage: "calendar")
                        .font(Theme.rounded(17, .bold))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    TagPill(text: "TODAY")
                }
                Text(todayKey)
                    .font(Theme.mono(13, .medium))
                    .foregroundStyle(Theme.inkSoft)
                if let result {
                    HStack(spacing: 8) {
                        Image(systemName: result.won ? "checkmark.seal.fill" : "xmark.seal.fill")
                            .foregroundStyle(result.won ? Theme.good : Theme.bad)
                        Text(result.won
                             ? "Solved in \(Formatters.clock(result.durationSec))"
                             : "Better luck — come back tomorrow")
                            .font(Theme.rounded(14, .medium))
                            .foregroundStyle(Theme.inkSoft)
                    }
                } else {
                    Text("Same board for everyone today. One sit-down — give it your best.")
                        .font(Theme.rounded(14))
                        .foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Button {
                    let seed = SeedFactory.seed(forDateKey: todayKey)
                    path.append(GameRoute.daily(dateKey: todayKey,
                                                       config: Difficulty.intermediate.preset,
                                                       seed: seed))
                } label: {
                    HStack {
                        Text(result == nil ? "Play today's board" : "Replay today")
                        Spacer()
                        Image(systemName: "arrow.right")
                    }
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(Theme.accent)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Best times

    private var bestTimesCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Your best times")
                    .font(Theme.rounded(17, .bold))
                    .foregroundStyle(Theme.ink)
                HStack(spacing: 8) {
                    bestChip(.beginner)
                    bestChip(.intermediate)
                    bestChip(.expert)
                }
            }
        }
    }

    private func bestChip(_ diff: Difficulty) -> some View {
        let best = StatsCalculator.bestTime(records, for: diff)
        return StatChip(label: diff.title,
                        value: best.map { Formatters.clock($0) } ?? "—",
                        tint: best == nil ? Theme.inkFaint : Theme.ink)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [GameRecord.self, SavedGame.self, DailyResult.self], inMemory: true)
}
