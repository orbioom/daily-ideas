import SwiftUI
import SwiftData

struct TrainView: View {
    @Environment(\.modelContext) private var context
    @Query private var results: [GameResult]

    @AppStorage("difficulty") private var difficultyRaw = Difficulty.medium.rawValue
    @AppStorage("duration") private var duration = 45

    @State private var workout: WorkoutLaunch?
    @State private var single: SingleLaunch?

    private var difficulty: Difficulty { Difficulty(rawValue: difficultyRaw) ?? .medium }
    private var todayGames: [Game] { StatsEngine.workoutGames() }
    private var streak: Int { StatsEngine.streak(results) }

    private var workoutDoneToday: Bool {
        let today = Calendar.current.startOfDay(for: .now)
        // A workout is "done" when results tagged with the same workoutID exist today.
        let todays = results.filter { Calendar.current.startOfDay(for: $0.date) == today && $0.workoutID != nil }
        let ids = Set(todays.compactMap { $0.workoutID })
        return ids.contains { id in todays.filter { $0.workoutID == id }.count >= todayGames.count }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    VStack(spacing: 18) {
                        header
                        workoutCard
                        Text("ALL GAMES")
                            .font(Brand.mono(12, weight: .medium)).tracking(1.4)
                            .foregroundStyle(Brand.text3)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        ForEach(Game.allCases) { game in
                            gameRow(game)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Train")
            .fullScreenCover(item: $workout) { w in
                WorkoutFlowView(games: w.games, difficulty: difficulty, duration: duration)
            }
            .fullScreenCover(item: $single) { s in
                SingleGameHost(game: s.game, difficulty: difficulty, duration: duration)
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Eyebrow(text: "Daily training")
                Text(streak > 0 ? "\(streak)-day streak" : "Train your mind")
                    .font(.title3.weight(.semibold)).foregroundStyle(Brand.text)
            }
            Spacer()
            ZStack {
                Circle().fill(Brand.magic.opacity(0.16)).frame(width: 48, height: 48)
                Image(systemName: "flame").foregroundStyle(streak > 0 ? Brand.magic : Brand.text3)
            }
            .accessibilityHidden(true)
        }
    }

    private var workoutCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Daily Workout", systemImage: "bolt.fill")
                    .font(.headline).foregroundStyle(Brand.text)
                Spacer()
                if workoutDoneToday {
                    Label("Done", systemImage: "checkmark.circle.fill")
                        .font(.subheadline).foregroundStyle(Brand.live).labelStyle(.titleAndIcon)
                }
            }
            HStack(spacing: 10) {
                ForEach(todayGames) { g in
                    VStack(spacing: 6) {
                        Image(systemName: g.icon).font(.title3).foregroundStyle(g.tint)
                        Text(g.title).font(.caption2).foregroundStyle(Brand.text2)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            Button {
                workout = WorkoutLaunch(games: todayGames)
                Haptics.tap()
            } label: {
                Label(workoutDoneToday ? "Train again" : "Start workout",
                      systemImage: "play.fill")
            }
            .buttonStyle(InkButtonStyle())
        }
        .padding(18)
        .glassCard()
    }

    private func gameRow(_ game: Game) -> some View {
        let s = StatsEngine.summary(results, game: game)
        return Button {
            single = SingleLaunch(game: game); Haptics.tap()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(game.tint.opacity(0.16)).frame(width: 50, height: 50)
                    Image(systemName: game.icon).font(.title3).foregroundStyle(game.tint)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(game.title).font(.headline).foregroundStyle(Brand.text)
                    Text(game.domain + " · " + game.blurb).font(.caption).foregroundStyle(Brand.text2)
                        .lineLimit(1)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Text(s.best > 0 ? "\(s.best)" : "—")
                        .font(Brand.mono(16, weight: .semibold)).foregroundStyle(Brand.text)
                    Text("best").font(.caption2).foregroundStyle(Brand.text3)
                }
            }
            .padding(14)
            .glassCard(padding: 0)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(game.title), \(game.domain). Best score \(s.best). Double tap to play.")
    }
}

struct WorkoutLaunch: Identifiable { let id = UUID(); let games: [Game] }
struct SingleLaunch: Identifiable { let id = UUID(); let game: Game }

#Preview {
    TrainView().modelContainer(for: GameResult.self, inMemory: true)
}
