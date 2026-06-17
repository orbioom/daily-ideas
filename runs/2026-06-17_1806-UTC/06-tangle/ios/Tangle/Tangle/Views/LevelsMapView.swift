import SwiftUI
import SwiftData

/// The Levels map: packs and their levels with completion stars and locked
/// progression. Pro unlocks every pack/level.
struct LevelsMapView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("isPro") private var isPro = false
    @Query private var progress: [LevelProgress]

    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 24, pinnedViews: []) {
                    headerCard
                    ForEach(LevelData.packs) { pack in
                        packSection(pack)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Tangle")
            .toolbar {
                if !isPro {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { showPaywall = true } label: {
                            Label("Pro", systemImage: "crown.fill")
                                .font(Theme.rounded(14, .bold))
                                .foregroundStyle(Theme.star)
                        }
                        .accessibilityLabel("Unlock Tangle Pro")
                    }
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private var progressByLevel: [String: LevelProgress] {
        Dictionary(progress.map { ($0.levelID, $0) }, uniquingKeysWith: { a, _ in a })
    }

    // MARK: - Header

    private var headerCard: some View {
        let total = LevelData.allLevels.count
        let done = progress.filter { $0.completed }.count
        let stars = progress.reduce(0) { $0 + $1.starsEarned }
        return VStack(alignment: .leading, spacing: 10) {
            Text("Word Crosswords")
                .font(Theme.rounded(22, .heavy))
                .foregroundStyle(.white)
            Text("Swipe the wheel, fill the grid, unwind.")
                .font(Theme.rounded(14, .medium))
                .foregroundStyle(.white.opacity(0.9))
            HStack(spacing: 18) {
                statChip(icon: "checkmark.circle.fill", value: "\(done)/\(total)", label: "Levels")
                statChip(icon: "star.fill", value: "\(stars)", label: "Stars")
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: Theme.radiusLarge, style: .continuous)
                .fill(Theme.heroGradient)
        )
        .padding(.top, 8)
    }

    private func statChip(icon: String, value: String, label: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 14, weight: .bold))
            Text(value).font(Theme.rounded(16, .bold))
            Text(label).font(Theme.rounded(13, .medium)).opacity(0.9)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Capsule().fill(.white.opacity(0.18)))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(value) \(label)")
    }

    // MARK: - Pack section

    private func packSection(_ pack: LevelPack) -> some View {
        let locked = pack.requiresPro && !isPro
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: pack.symbol)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(pack.title).font(Theme.rounded(18, .bold)).foregroundStyle(Theme.ink)
                    Text(pack.subtitle).font(Theme.rounded(13)).foregroundStyle(Theme.inkSoft)
                }
                Spacer()
                if locked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Theme.inkSoft)
                        .accessibilityLabel("Locked, requires Pro")
                }
            }

            VStack(spacing: 10) {
                ForEach(Array(pack.levels.enumerated()), id: \.element.id) { idx, level in
                    levelRow(pack: pack, level: level, indexInPack: idx, packLocked: locked)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: Theme.radiusLarge, style: .continuous)
                .fill(Theme.surface)
                .overlay(RoundedRectangle(cornerRadius: Theme.radiusLarge, style: .continuous).strokeBorder(Theme.hairline, lineWidth: 1))
        )
    }

    /// A level is unlocked if: pack is free-and-unlocked AND (it's the first level
    /// of the global list, or the previous level is completed). Pro unlocks all.
    private func isUnlocked(_ level: Level, packLocked: Bool) -> Bool {
        if isPro { return true }
        if packLocked { return false }
        guard let globalIdx = LevelData.globalIndex(of: level.id) else { return false }
        if globalIdx == 0 { return true }
        let all = LevelData.allLevels
        guard all.indices.contains(globalIdx - 1) else { return true }
        let prevID = all[globalIdx - 1].id
        return progressByLevel[prevID]?.completed == true
    }

    @ViewBuilder
    private func levelRow(pack: LevelPack, level: Level, indexInPack: Int, packLocked: Bool) -> some View {
        let unlocked = isUnlocked(level, packLocked: packLocked)
        let prog = progressByLevel[level.id]
        let completed = prog?.completed == true

        Group {
            if unlocked {
                NavigationLink {
                    LevelPlayView(level: level)
                } label: {
                    rowContent(level: level, indexInPack: indexInPack, completed: completed, stars: prog?.starsEarned ?? 0, locked: false)
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    if packLocked { showPaywall = true }
                } label: {
                    rowContent(level: level, indexInPack: indexInPack, completed: false, stars: 0, locked: true)
                }
                .buttonStyle(.plain)
                .accessibilityHint(packLocked ? "Locked. Unlock Pro to play." : "Locked. Finish the previous level to unlock.")
            }
        }
    }

    private func rowContent(level: Level, indexInPack: Int, completed: Bool, stars: Int, locked: Bool) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(completed ? AnyShapeStyle(Theme.accentSoft) : AnyShapeStyle(Theme.surfaceSunken))
                    .frame(width: 40, height: 40)
                if locked {
                    Image(systemName: "lock.fill").font(.system(size: 15, weight: .bold)).foregroundStyle(Theme.inkSoft)
                } else if completed {
                    Image(systemName: "checkmark").font(.system(size: 16, weight: .bold)).foregroundStyle(Theme.accentDeep)
                } else {
                    Text("\(indexInPack + 1)").font(Theme.rounded(16, .bold)).foregroundStyle(Theme.ink)
                }
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(level.title)
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(locked ? Theme.inkSoft : Theme.ink)
                Text("\(level.baseWord.count) letters")
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkSoft)
            }
            Spacer()
            if completed {
                StarRatingView(stars: stars)
            } else if !locked {
                Image(systemName: "chevron.right").font(.system(size: 13, weight: .bold)).foregroundStyle(Theme.inkSoft)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: Theme.radiusMedium, style: .continuous).fill(Theme.bg.opacity(0.5)))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(level.title), \(level.baseWord.count) letters")
        .accessibilityValue(locked ? "Locked" : (completed ? "Completed, \(stars) stars" : "Not played"))
    }
}
