import SwiftUI

/// The live scorecard. Shows each player's column, previews for open categories of the
/// current (human) player, and lets the human tap an open row to score the current dice.
struct ScorecardView: View {
    let engine: GameEngine
    let sortByValue: Bool
    let canInteract: Bool
    let onScore: (ScoreCategory) -> Void

    private var orderedCategories: [ScoreCategory] {
        guard sortByValue, let _ = engine.currentPlayer, engine.canScore else {
            return ScoreCategory.allCases
        }
        // Sort open categories by descending preview; keep filled ones after in canonical order.
        let open = ScoreCategory.allCases.filter { engine.currentPlayer?.scores[$0] == nil }
        let filled = ScoreCategory.allCases.filter { engine.currentPlayer?.scores[$0] != nil }
        let sortedOpen = open.sorted { engine.preview($0) > engine.preview($1) }
        return sortedOpen + filled
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            ForEach(Array(orderedCategories.enumerated()), id: \.element.id) { idx, cat in
                if idx > 0 { Divider().background(Theme.hairline) }
                ScoreRow(
                    engine: engine,
                    category: cat,
                    canInteract: canInteract,
                    onScore: onScore
                )
            }
            Divider().background(Theme.hairline)
            totalsRow
        }
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.rCard, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.rCard, style: .continuous)
                .strokeBorder(Theme.hairline, lineWidth: 1)
        )
    }

    private var header: some View {
        HStack(spacing: 0) {
            Text("Category")
                .font(Theme.rounded(13, .bold))
                .foregroundStyle(Theme.inkSoft)
                .frame(maxWidth: .infinity, alignment: .leading)
            ForEach(Array(engine.players.enumerated()), id: \.element.id) { idx, player in
                Text(initials(player.name))
                    .font(Theme.rounded(13, .bold))
                    .foregroundStyle(idx == engine.currentPlayerIndex ? Theme.accent : Theme.inkSoft)
                    .frame(width: columnWidth)
                    .accessibilityLabel(player.name)
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(Theme.surfaceAlt)
    }

    private var totalsRow: some View {
        HStack(spacing: 0) {
            Text("Total")
                .font(Theme.rounded(15, .bold))
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
            ForEach(Array(engine.players.enumerated()), id: \.element.id) { idx, player in
                Text("\(player.grandTotal)")
                    .font(Theme.rounded(16, .bold))
                    .foregroundStyle(idx == engine.currentPlayerIndex ? Theme.accent : Theme.ink)
                    .frame(width: columnWidth)
                    .accessibilityLabel("\(player.name) total \(player.grandTotal)")
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(Theme.surfaceAlt)
    }

    private var columnWidth: CGFloat {
        let n = CGFloat(max(1, engine.players.count))
        // Narrower columns as players grow; clamp for readability.
        return max(40, 70 - (n - 1) * 8)
    }

    private func initials(_ name: String) -> String {
        let parts = name.split(separator: " ")
        if let first = parts.first {
            return String(first.prefix(parts.count > 1 ? 1 : 4)).uppercased()
        }
        return "P"
    }
}

/// One scorecard row across all players.
private struct ScoreRow: View {
    let engine: GameEngine
    let category: ScoreCategory
    let canInteract: Bool
    let onScore: (ScoreCategory) -> Void

    private var isOpenForCurrent: Bool {
        engine.currentPlayer?.scores[category] == nil
    }
    private var previewValue: Int { engine.preview(category) }
    private var showsPreview: Bool {
        canInteract && engine.canScore && isOpenForCurrent
    }
    private var awardsBonus: Bool { engine.previewAwardsYahtzeeBonus(category) }

    private var columnWidth: CGFloat {
        let n = CGFloat(max(1, engine.players.count))
        return max(40, 70 - (n - 1) * 8)
    }

    var body: some View {
        Button {
            if showsPreview { onScore(category) }
        } label: {
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(category.shortTitle)
                        .font(Theme.rounded(15, .semibold))
                        .foregroundStyle(Theme.ink)
                    if category == .sixes {
                        upperProgressLabel
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                ForEach(Array(engine.players.enumerated()), id: \.element.id) { idx, player in
                    cell(for: player, isCurrent: idx == engine.currentPlayerIndex)
                        .frame(width: columnWidth)
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 9)
            .background(showsPreview ? Theme.accentSoft.opacity(0.45) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!showsPreview)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(showsPreview ? "Double tap to score \(previewValue) points here" : "")
        .accessibilityAddTraits(showsPreview ? .isButton : [])
    }

    @ViewBuilder
    private var upperProgressLabel: some View {
        if let player = engine.currentPlayer {
            let sub = player.upperSubtotal
            Text("Upper \(sub)/63\(sub >= 63 ? " +35" : "")")
                .font(Theme.rounded(11, .medium))
                .foregroundStyle(sub >= 63 ? Theme.good : Theme.inkSoft)
        }
    }

    @ViewBuilder
    private func cell(for player: PlayerState, isCurrent: Bool) -> some View {
        if let scored = player.scores[category] {
            Text("\(scored)")
                .font(Theme.rounded(15, .semibold))
                .foregroundStyle(Theme.ink)
        } else if isCurrent && showsPreview {
            HStack(spacing: 2) {
                Text("\(previewValue)")
                    .font(Theme.rounded(15, .bold))
                    .foregroundStyle(previewValue > 0 ? Theme.accent : Theme.inkSoft)
                if awardsBonus {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.gold)
                }
            }
        } else {
            Text("–")
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.hairline)
        }
    }

    private var accessibilityLabel: String {
        var label = category.title
        if let player = engine.currentPlayer {
            if let scored = player.scores[category] {
                label += ", scored \(scored)"
            } else if showsPreview {
                label += ", previews \(previewValue) points"
                if awardsBonus { label += ", plus a Yahtzee bonus" }
            } else {
                label += ", open"
            }
        }
        return label
    }
}
