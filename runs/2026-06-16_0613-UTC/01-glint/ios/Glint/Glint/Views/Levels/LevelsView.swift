import SwiftUI
import SwiftData

struct LevelsView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var pro: ProStore
    @Query private var progress: [LevelProgress]

    @State private var showPaywall = false
    @State private var showHowTo = false

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 14)]

    private func progressFor(_ id: Int) -> LevelProgress? {
        progress.first { $0.levelID == id }
    }

    private func isUnlocked(_ level: Level) -> Bool {
        if level.id == 1 { return true }
        return progressFor(level.id)?.unlocked ?? false
    }

    var totalStars: Int { progress.reduce(0) { $0 + $1.stars } }

    var body: some View {
        NavigationStack {
            ZStack {
                ScreenBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        header
                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(LevelCatalog.all) { level in
                                levelCard(level)
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Levels")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showHowTo = true } label: {
                        Image(systemName: "questionmark.circle")
                    }
                    .accessibilityLabel("How to play")
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(isPresented: $showHowTo) { HowToPlayView() }
        }
    }

    private var header: some View {
        GlintCard {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Theme.accent.opacity(0.15)).frame(width: 54, height: 54)
                    Image(systemName: "star.fill").foregroundStyle(Theme.gold).font(.system(size: 24))
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(totalStars) stars earned")
                        .font(Theme.rounded(19, .bold))
                        .foregroundStyle(Theme.ink)
                    Text(pro.isPro ? "All packs unlocked" : "Free pack: levels 1–\(LevelCatalog.freePackSize)")
                        .font(Theme.rounded(14))
                        .foregroundStyle(Theme.inkSoft)
                }
                Spacer()
                if !pro.isPro {
                    Button { showPaywall = true } label: {
                        Text("Pro")
                            .font(Theme.rounded(14, .bold))
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(Theme.heroGradient)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private func levelCard(_ level: Level) -> some View {
        let prog = progressFor(level.id)
        let unlocked = isUnlocked(level)
        let proLocked = ProGate.isLevelLocked(level, isPro: pro.isPro)

        if unlocked && !proLocked {
            NavigationLink {
                PlayView(config: PlayConfig(mode: .level, level: level,
                                            seed: UInt64(level.id) &* 2654435761))
            } label: {
                cardBody(level: level, prog: prog, locked: false, proLocked: false)
            }
            .buttonStyle(.plain)
        } else {
            Button {
                if proLocked { showPaywall = true }
            } label: {
                cardBody(level: level, prog: prog, locked: !unlocked, proLocked: proLocked)
            }
            .buttonStyle(.plain)
            .disabled(!proLocked && !unlocked)
        }
    }

    private func cardBody(level: Level, prog: LevelProgress?, locked: Bool, proLocked: Bool) -> some View {
        VStack(spacing: 10) {
            HStack {
                Text("\(level.id)")
                    .font(Theme.rounded(26, .black))
                    .foregroundStyle(locked || proLocked ? Theme.inkSoft : Theme.accent)
                Spacer()
                if proLocked {
                    Image(systemName: "crown.fill").foregroundStyle(Theme.gold)
                } else if locked {
                    Image(systemName: "lock.fill").foregroundStyle(Theme.inkSoft)
                }
            }
            HStack(spacing: 6) {
                Image(systemName: level.goal.icon)
                    .font(.system(size: 12))
                Text(level.shortGoalText)
                    .font(Theme.rounded(13, .medium))
                    .lineLimit(1)
            }
            .foregroundStyle(Theme.inkSoft)
            .frame(maxWidth: .infinity, alignment: .leading)

            StarRow(stars: prog?.stars ?? 0, size: 14)
                .opacity(locked || proLocked ? 0.4 : 1)

            if let best = prog?.bestScore, best > 0 {
                Text("Best \(best)")
                    .font(Theme.rounded(11, .medium))
                    .foregroundStyle(Theme.inkSoft)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 130)
        .background(
            RoundedRectangle(cornerRadius: Theme.rMed, style: .continuous)
                .fill(Theme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.rMed, style: .continuous)
                        .stroke((prog?.completed ?? false) ? Theme.accent.opacity(0.5) : Theme.hairline,
                                lineWidth: (prog?.completed ?? false) ? 1.5 : 1)
                )
        )
        .opacity(locked && !proLocked ? 0.6 : 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText(level: level, prog: prog, locked: locked, proLocked: proLocked))
    }

    private func accessibilityText(level: Level, prog: LevelProgress?, locked: Bool, proLocked: Bool) -> String {
        if proLocked { return "Level \(level.id), Pro locked. \(level.goalText)" }
        if locked { return "Level \(level.id), locked. Clear the previous level to unlock." }
        return "Level \(level.id), \(prog?.stars ?? 0) stars. \(level.goalText)"
    }
}
