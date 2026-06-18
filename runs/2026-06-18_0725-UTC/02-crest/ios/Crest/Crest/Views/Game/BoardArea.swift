import SwiftUI
import SwiftData

/// Renders the tableau: overlapping cards positioned by the layout's normalized
/// coordinates, with depth shading and tap-to-play. Index-guarded throughout.
struct BoardArea: View {
    @Bindable var vm: GameViewModel
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let spec = vm.layout.spec
        GeometryReader { geo in
            let layout = boardMetrics(in: geo.size, spec: spec)
            ZStack {
                ForEach(spec.positions) { pos in
                    cardSlot(pos: pos, layout: layout, spec: spec)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .aspectRatio(spec.aspect, contentMode: .fit)
        .frame(maxWidth: .infinity)
    }

    // MARK: Metrics

    private struct Metrics {
        let cardW: CGFloat
        let cardH: CGFloat
        let originX: CGFloat
        let originY: CGFloat
        let spanW: CGFloat
        let spanH: CGFloat
    }

    private func boardMetrics(in size: CGSize, spec: BoardSpec) -> Metrics {
        // Choose a card width so the whole normalized layout fits in `size`.
        // Cards are 0.7 aspect (w:h). We estimate the columns from positions' x.
        let columnsEstimate: CGFloat
        switch vm.layout {
        case .threePeaks: columnsEstimate = 10.5
        case .pyramid: columnsEstimate = 7.5
        case .diamond: columnsEstimate = 5.6
        }
        let byWidth = size.width / columnsEstimate
        // Rows: estimate vertical card count.
        let rowsEstimate: CGFloat
        switch vm.layout {
        case .threePeaks: rowsEstimate = 3.6
        case .pyramid: rowsEstimate = 4.6
        case .diamond: rowsEstimate = 5.0
        }
        let byHeight = (size.height / rowsEstimate) * 0.7
        let cardW = max(28, min(byWidth, byHeight))
        let cardH = cardW / 0.7
        return Metrics(cardW: cardW, cardH: cardH,
                       originX: cardW / 2, originY: cardH / 2,
                       spanW: size.width - cardW, spanH: size.height - cardH)
    }

    // MARK: Slot

    @ViewBuilder
    private func cardSlot(pos: BoardPosition, layout: Metrics, spec: BoardSpec) -> some View {
        let i = pos.id
        let playable = vm.isPlayable(i)
        let legal = vm.isLegalNow(i)
        let hinted = vm.hintedPosition == i
        let x = layout.originX + pos.x * layout.spanW
        let y = layout.originY + pos.y * layout.spanH
        // Depth shading: deeper rows sit "higher" in the stack visually.
        let depth = Double(pos.row)

        Group {
            if let card = vm.card(at: i) {
                CardView(card: card,
                         faceUp: playable,
                         playable: legal,
                         hinted: hinted,
                         dimmed: playable && !legal)
                    .frame(width: layout.cardW, height: layout.cardH)
                    .overlay {
                        if !playable {
                            // Cover scrim so still-covered cards read as "down".
                            RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous)
                                .fill(Color.black.opacity(min(0.06 * depth, 0.22)))
                        }
                    }
                    .contentShape(RoundedRectangle(cornerRadius: Theme.radiusCard, style: .continuous))
                    .onTapGesture { tap(i) }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(card.accessibilityName)
                    .accessibilityValue(legal ? "playable" : (playable ? "open" : "covered"))
                    .accessibilityHint(legal ? "Double tap to play onto the waste" : "")
                    .accessibilityAddTraits(legal ? .isButton : [])
            }
        }
        .position(x: x, y: y)
        .zIndex(depth)
        .animation(reduceMotion ? nil : .spring(response: 0.32, dampingFraction: 0.82), value: vm.card(at: i) == nil)
    }

    private func tap(_ i: Int) {
        guard vm.outcome == .playing else { return }
        let didPlay = vm.play(i, settings: settings)
        if didPlay {
            vm.persist(into: context)
        }
    }
}
