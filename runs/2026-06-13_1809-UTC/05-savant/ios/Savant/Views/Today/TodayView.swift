import SwiftUI
import SwiftData

/// Describes a round to launch in the full-screen quiz cover.
struct GameLaunch: Identifiable {
    let id = UUID()
    let questions: [PlayableQuestion]
    let mode: GameMode
    let category: TriviaCategory?
}

struct TodayView: View {
    @Query(sort: \GameResult.date, order: .reverse) private var results: [GameResult]
    @State private var launch: GameLaunch?

    private var todayDaily: GameResult? { StatsEngine.isDailyDone(results: results) }
    private var streak: Int { StatsEngine.dailyStreak(results: results) }
    private var bestDaily: Int { StatsEngine.bestDailyScore(results) }
    private var accuracy: Double? { StatsEngine.overallAccuracy(results) }

    private let quickCategories: [TriviaCategory] = [.science, .history, .geography, .screen]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        dailyCard
                        statsRow
                        quickPlay
                    }
                    .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 28)
                }
            }
            .navigationTitle("Savant")
            .fullScreenCover(item: $launch) { g in
                QuizContainerView(questions: g.questions, mode: g.mode, category: g.category)
            }
        }
    }

    private var dailyCard: some View {
        Card(padding: 22) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text(Date().formatted(.dateTime.weekday(.wide).month().day()))
                        .font(Theme.rounded(13, .semibold)).foregroundStyle(Theme.inkSoft)
                    Spacer()
                    Image(systemName: "bolt.fill").foregroundStyle(Theme.gold)
                }
                Text("Daily Challenge").font(Theme.serif(28, .bold)).foregroundStyle(Theme.ink)
                if let done = todayDaily {
                    Text("Done for today — you scored \(done.score) points (\(done.correct)/\(done.total)). Come back tomorrow for a fresh set!")
                        .font(Theme.rounded(15, .regular)).foregroundStyle(Theme.inkSoft)
                    Button { startPracticeMixed() } label: {
                        Text("Play a practice round")
                            .font(Theme.rounded(17, .bold)).frame(maxWidth: .infinity).padding(.vertical, 15)
                            .background(Theme.surfaceAlt, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .foregroundStyle(Theme.accent)
                    }
                } else {
                    Text("\(QuizEngine.dailyCount) questions across every category — the same for everyone today. Beat the clock!")
                        .font(Theme.rounded(15, .regular)).foregroundStyle(Theme.inkSoft)
                    Button { startDaily() } label: {
                        Label("Play today’s quiz", systemImage: "play.fill")
                            .font(Theme.rounded(17, .bold)).frame(maxWidth: .infinity).padding(.vertical, 15)
                            .background(Theme.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .foregroundStyle(.white)
                    }
                }
            }
        }
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            StatTile(value: "\(streak)", label: streak == 1 ? "day streak" : "day streak", accent: Theme.gold)
            StatTile(value: bestDaily > 0 ? "\(bestDaily)" : "—", label: "Best daily", accent: Theme.accent)
            StatTile(value: accuracy.map { "\(Int($0 * 100))%" } ?? "—", label: "Accuracy", accent: Theme.good)
        }
    }

    private var quickPlay: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Quick practice").font(Theme.rounded(15, .bold)).foregroundStyle(Theme.ink)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(quickCategories) { cat in
                        Button { startPractice(cat) } label: {
                            HStack(spacing: 8) {
                                Image(systemName: cat.icon).foregroundStyle(Theme.accent)
                                Text(cat.label).font(Theme.rounded(14, .bold)).foregroundStyle(Theme.ink)
                                Spacer()
                            }
                            .padding(.horizontal, 14).padding(.vertical, 14)
                            .background(Theme.surfaceAlt, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func startDaily() {
        Haptics.tap()
        launch = GameLaunch(questions: QuizEngine.daily(for: Date()), mode: .daily, category: nil)
    }
    private func startPracticeMixed() {
        Haptics.tap()
        launch = GameLaunch(questions: QuizEngine.practice(category: nil, difficulty: nil, count: 10), mode: .practice, category: nil)
    }
    private func startPractice(_ cat: TriviaCategory) {
        Haptics.tap()
        launch = GameLaunch(questions: QuizEngine.practice(category: cat, difficulty: nil, count: 10), mode: .practice, category: cat)
    }
}
