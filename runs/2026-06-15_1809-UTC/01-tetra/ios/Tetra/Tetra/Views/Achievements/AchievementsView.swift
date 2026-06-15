import SwiftUI
import SwiftData

struct AchievementsView: View {
    @Query private var records: [GameRecord]

    private var achievements: [Achievement] {
        AchievementEngine.compute(records: records)
    }

    private var unlockedCount: Int { achievements.filter(\.unlocked).count }

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 12)]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        progressHeader
                        if records.isEmpty {
                            EmptyStateView(
                                symbol: "trophy",
                                title: "Awards await",
                                message: "Play your first games to start unlocking badges — reach big tiles, rack up wins, and climb the score ladders."
                            )
                            .padding(.top, 8)
                        }
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(achievements) { badge in
                                AchievementCard(badge: badge)
                            }
                        }
                    }
                    .padding(18)
                }
            }
            .navigationTitle("Awards")
        }
    }

    private var progressHeader: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
                Text("\(unlockedCount) of \(achievements.count) unlocked")
                    .font(Theme.rounded(17, .bold))
                    .foregroundStyle(Theme.ink)
                Spacer()
            }
            ProgressBar(progress: achievements.isEmpty ? 0 : Double(unlockedCount) / Double(achievements.count))
                .frame(height: 10)
        }
        .padding(18)
        .cardSurface()
        .accessibilityElement(children: .combine)
    }
}

private struct AchievementCard: View {
    let badge: Achievement

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ZStack {
                    Circle()
                        .fill(badge.unlocked ? AnyShapeStyle(Theme.heroGradient) : AnyShapeStyle(Theme.surfaceAlt))
                        .frame(width: 44, height: 44)
                    Image(systemName: badge.symbol)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(badge.unlocked ? .white : Theme.inkFaint)
                        .accessibilityHidden(true)
                }
                Spacer()
                if badge.unlocked {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.good)
                        .accessibilityHidden(true)
                }
            }
            Text(badge.title)
                .font(Theme.rounded(16, .bold))
                .foregroundStyle(Theme.ink)
            Text(badge.detail)
                .font(Theme.rounded(12))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            ProgressBar(progress: badge.progress)
                .frame(height: 7)
            Text(badge.progressLabel)
                .font(Theme.rounded(11, .semibold))
                .foregroundStyle(badge.unlocked ? Theme.good : Theme.inkFaint)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 180, alignment: .topLeading)
        .cardSurface()
        .opacity(badge.unlocked ? 1 : 0.92)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(badge.title). \(badge.detail)")
        .accessibilityValue(badge.unlocked ? "Unlocked" : "In progress, \(badge.progressLabel)")
    }
}

/// A rounded progress bar in the app's accent.
struct ProgressBar: View {
    /// 0...1
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            let clamped = max(0, min(1, progress))
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.surfaceAlt)
                Capsule()
                    .fill(Theme.heroGradient)
                    .frame(width: geo.size.width * clamped)
            }
        }
        .accessibilityHidden(true)
    }
}
