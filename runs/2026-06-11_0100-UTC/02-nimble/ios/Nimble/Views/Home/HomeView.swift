import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var vm = TrainingViewModel()
    @State private var launchGame: GameType? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                dailySummary
                gameGrid
                Spacer(minLength: 20)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .navigationTitle("Nimble")
        .navigationBarTitleDisplayMode(.large)
        .task { vm.load(modelContext: modelContext) }
        .sheet(item: $launchGame) { type in
            gameSheet(for: type)
        }
    }

    // MARK: Daily summary card

    private var dailySummary: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Training")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                    Text(vm.todayAllDone ? "All done! 🎉" :
                         "\(vm.completedGameTypes.count) of \(GameType.allCases.count) games complete")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let result = vm.todayResult {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(result.totalScore)")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundStyle(NimbleTheme.scoreColor(result.averageScore))
                        Text("/ \(GameType.allCases.count * 100)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Score: \(result.totalScore) out of \(GameType.allCases.count * 100)")
                }
            }

            ProgressView(value: vm.todayProgressFraction)
                .tint(.cyan)
                .scaleEffect(x: 1, y: 2, anchor: .center)
                .accessibilityLabel("\(Int(vm.todayProgressFraction * 100))% of today's training complete")
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: Game grid

    private var gameGrid: some View {
        VStack(spacing: 12) {
            Text("Games")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityAddTraits(.isHeader)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(GameType.allCases, id: \.self) { type in
                    GameCardView(
                        type: type,
                        completed: vm.completedGameTypes.contains(type)
                    ) {
                        launchGame = type
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func gameSheet(for type: GameType) -> some View {
        NavigationStack {
            gameView(for: type)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { launchGame = nil }
                    }
                }
        }
        .onDisappear { vm.load(modelContext: modelContext) }
    }

    @ViewBuilder
    private func gameView(for type: GameType) -> some View {
        switch type {
        case .memoryGrid:
            MemoryGridGameView { score, dur, lv in
                vm.recordSession(gameType: type, score: score, duration: dur, level: lv, modelContext: modelContext)
                launchGame = nil
            }
        case .quickMath:
            QuickMathGameView { score, dur, lv in
                vm.recordSession(gameType: type, score: score, duration: dur, level: lv, modelContext: modelContext)
                launchGame = nil
            }
        case .wordFlash:
            WordFlashGameView { score, dur, lv in
                vm.recordSession(gameType: type, score: score, duration: dur, level: lv, modelContext: modelContext)
                launchGame = nil
            }
        case .patternGame:
            PatternGameView { score, dur, lv in
                vm.recordSession(gameType: type, score: score, duration: dur, level: lv, modelContext: modelContext)
                launchGame = nil
            }
        case .reactionGame:
            ReactionGameView { score, dur, lv in
                vm.recordSession(gameType: type, score: score, duration: dur, level: lv, modelContext: modelContext)
                launchGame = nil
            }
        }
    }
}

struct GameCardView: View {
    let type: GameType
    let completed: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: type.icon)
                        .font(.title2)
                        .foregroundStyle(completed ? .white : NimbleTheme.gameColor(for: type))
                        .accessibilityHidden(true)
                    Spacer()
                    if completed {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.white.opacity(0.8))
                            .accessibilityHidden(true)
                    }
                }
                Text(type.rawValue)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(completed ? .white : .primary)
                Text(type.description)
                    .font(.system(size: 11))
                    .foregroundStyle(completed ? .white.opacity(0.8) : .secondary)
                    .lineLimit(2)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(completed ? NimbleTheme.gameColor(for: type) : Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(type.rawValue): \(type.description). \(completed ? "Completed today." : "Tap to play.")")
        .accessibilityAddTraits(.isButton)
    }
}
