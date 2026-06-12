import SwiftUI
import SwiftData

struct BadgesView: View {
    @Query private var unlocked: [Badge]
    @Query(sort: \DayLog.day, order: .reverse) private var logs: [DayLog]

    private var unlockedKeys: Set<String> { Set(unlocked.map(\.key)) }

    private var earnedCount: Int { unlockedKeys.count }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bgPrimary.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        header
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(BadgeCatalog.all) { def in
                                BadgeCard(def: def,
                                          isUnlocked: unlockedKeys.contains(def.id),
                                          progress: progress(for: def))
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Badges")
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text("\(earnedCount) of \(BadgeCatalog.all.count)")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.accent)
            Text("milestones earned")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .treadCard()
    }

    private func progress(for def: BadgeDef) -> Double {
        let total = StepEngine.totalSteps(logs: logs)
        let streak = max(StepEngine.currentStreak(logs: logs), StepEngine.longestStreak(logs: logs))
        let maxDay = logs.map(\.steps).max() ?? 0
        switch def.kind {
        case .singleDaySteps(let n): return min(Double(maxDay) / Double(n), 1)
        case .streak(let n):         return min(Double(streak) / Double(n), 1)
        case .totalSteps(let n):     return min(Double(total) / Double(n), 1)
        }
    }
}

struct BadgeCard: View {
    let def: BadgeDef
    let isUnlocked: Bool
    let progress: Double

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? Theme.accent.opacity(0.15) : Theme.track)
                    .frame(width: 64, height: 64)
                Image(systemName: def.symbol)
                    .font(.system(size: 26))
                    .foregroundStyle(isUnlocked ? Theme.accent : Theme.textSecondary.opacity(0.6))
            }
            Text(def.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
            Text(def.detail)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
            if !isUnlocked {
                ProgressView(value: progress)
                    .tint(Theme.accent)
                    .padding(.top, 2)
            } else {
                Label("Earned", systemImage: "checkmark.seal.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.accent)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 180)
        .treadCard()
        .opacity(isUnlocked ? 1 : 0.92)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(def.title), \(def.detail)")
        .accessibilityValue(isUnlocked ? "Earned" : "\(Int(progress * 100)) percent")
    }
}
