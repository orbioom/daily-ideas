import SwiftUI

/// A vertical map of curriculum levels: completed, current, unlocked, or Pro-locked.
struct LevelMapView: View {
    let profile: Profile
    let onLockedTap: () -> Void
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Curriculum.levels) { level in
                LevelRow(level: level,
                         state: state(for: level),
                         progress: ProgressEngine.levelProgress(level, facts: profile.facts),
                         isLast: level.id == Curriculum.levels.count - 1,
                         onLockedTap: onLockedTap)
            }
        }
    }

    enum LevelState { case completed, current, unlocked, locked }

    private func state(for level: Level) -> LevelState {
        if level.requiresPro && !settings.isPro { return .locked }
        if level.id < profile.currentLevelIndex {
            return ProgressEngine.isLevelPassed(level, facts: profile.facts) ? .completed : .unlocked
        }
        if level.id == profile.currentLevelIndex { return .current }
        return .unlocked
    }
}

private struct LevelRow: View {
    let level: Level
    let state: LevelMapView.LevelState
    let progress: Double
    let isLast: Bool
    let onLockedTap: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Rail + node
            VStack(spacing: 0) {
                ZStack {
                    Circle().fill(nodeColor).frame(width: 36, height: 36)
                    Image(systemName: nodeSymbol)
                        .font(Theme.rounded(15, .bold))
                        .foregroundStyle(.white)
                }
                if !isLast {
                    Rectangle()
                        .fill(Theme.hairline)
                        .frame(width: 3)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 36)

            // Card
            Button {
                if state == .locked { onLockedTap() }
            } label: {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("\(level.emoji) \(level.title)")
                            .font(Theme.rounded(17, .bold))
                            .foregroundStyle(Theme.ink)
                        Spacer()
                        statusTag
                    }
                    Text(level.subtitle)
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                    if state == .current || state == .completed {
                        ProgressView(value: min(1, max(0, progress)))
                            .tint(state == .completed ? Theme.good : Theme.accent)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(state == .current ? Theme.accent.opacity(0.08) : Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: Theme.rMedium, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: Theme.rMedium, style: .continuous)
                    .stroke(state == .current ? Theme.accent : Theme.hairline,
                            lineWidth: state == .current ? 2 : 1))
            }
            .disabled(state != .locked)
            .padding(.bottom, 12)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(level.title). \(statusText)")
    }

    private var nodeColor: Color {
        switch state {
        case .completed: return Theme.good
        case .current: return Theme.accent
        case .unlocked: return Theme.inkSoft
        case .locked: return Theme.inkSoft.opacity(0.5)
        }
    }

    private var nodeSymbol: String {
        switch state {
        case .completed: return "checkmark"
        case .current: return "play.fill"
        case .unlocked: return "circle.fill"
        case .locked: return "lock.fill"
        }
    }

    @ViewBuilder
    private var statusTag: some View {
        Text(statusText)
            .font(Theme.rounded(11, .bold))
            .foregroundStyle(tagColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(tagColor.opacity(0.14))
            .clipShape(Capsule())
    }

    private var statusText: String {
        switch state {
        case .completed: return "Completed"
        case .current: return "In progress"
        case .unlocked: return "Unlocked"
        case .locked: return "Pro"
        }
    }

    private var tagColor: Color {
        switch state {
        case .completed: return Theme.good
        case .current: return Theme.accent
        case .unlocked: return Theme.inkSoft
        case .locked: return Theme.opMul
        }
    }
}
