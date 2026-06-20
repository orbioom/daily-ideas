import SwiftUI
import SwiftData

struct LevelSelectView: View {
    @Bindable var game: OrbGame
    @Binding var selectedTab: Int
    @AppStorage("highestLevelReached") private var highestLevelReached = 1
    @Query private var results: [OrbResult]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)

    var body: some View {
        NavigationStack {
            ZStack {
                OrbTheme.background.ignoresSafeArea()

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(LevelDefinition.all, id: \.number) { level in
                            LevelCell(
                                level: level,
                                isUnlocked: level.number <= highestLevelReached,
                                isCurrent: level.number == game.currentLevel,
                                bestResult: results
                                    .filter { $0.level == level.number && $0.won }
                                    .max(by: { $0.score < $1.score })
                            )
                            .onTapGesture {
                                guard level.number <= highestLevelReached else { return }
                                game.loadLevel(level.number)
                                selectedTab = 0
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Levels")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct LevelCell: View {
    let level: LevelDefinition
    let isUnlocked: Bool
    let isCurrent: Bool
    let bestResult: OrbResult?

    private var stars: Int {
        guard let result = bestResult, let par = level.parShots else { return 0 }
        if result.shotsUsed <= par { return 3 }
        if result.shotsUsed <= par + 5 { return 2 }
        return 1
    }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        isCurrent
                            ? OrbTheme.accent.opacity(0.3)
                            : (isUnlocked ? OrbTheme.surface : OrbTheme.background)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(
                                isCurrent
                                    ? OrbTheme.accent
                                    : (isUnlocked ? Color.white.opacity(0.1) : Color.clear),
                                lineWidth: isCurrent ? 2 : 1
                            )
                    )

                if isUnlocked {
                    VStack(spacing: 2) {
                        Text("\(level.number)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(isCurrent ? OrbTheme.accent : .white)

                        if stars > 0 {
                            HStack(spacing: 1) {
                                ForEach(1...3, id: \.self) { s in
                                    Image(systemName: s <= stars ? "star.fill" : "star")
                                        .font(.system(size: 8))
                                        .foregroundColor(
                                            s <= stars ? OrbTheme.starGold : Color.white.opacity(0.2)
                                        )
                                }
                            }
                        }
                    }
                } else {
                    Image(systemName: "lock.fill")
                        .font(.title3)
                        .foregroundColor(Color.white.opacity(0.3))
                }
            }
            .frame(height: 70)
        }
    }
}
