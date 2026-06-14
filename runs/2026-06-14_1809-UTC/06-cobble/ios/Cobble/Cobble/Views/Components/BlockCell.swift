import SwiftUI

/// One rendered block: a glassy rounded fill with a soft top highlight. Used for both the
/// board's filled cells and the tray pieces. An empty cell renders the calm grid well.
struct BlockCell: View {
    /// 0 = empty well; >0 = filled with the palette color.
    let colorIndex: Int
    let palette: BlockPalette
    var size: CGFloat
    /// Visual state for previews/flashes.
    var ghostState: GhostState = .none
    var corner: CGFloat = 5

    enum GhostState { case none, valid, invalid, flashing }

    var body: some View {
        ZStack {
            if colorIndex > 0 {
                filledBlock
            } else {
                emptyWell
            }
            ghostOverlay
        }
        .frame(width: size, height: size)
    }

    private var fill: Color { palette.color(colorIndex) }

    private var filledBlock: some View {
        RoundedRectangle(cornerRadius: corner, style: .continuous)
            .fill(fill)
            .overlay(
                // Soft top highlight for the glassy look.
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(
                        LinearGradient(colors: [Color.white.opacity(0.45), Color.white.opacity(0.0)],
                                       startPoint: .top, endPoint: .center)
                    )
                    .padding(1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.10), lineWidth: 1)
            )
    }

    private var emptyWell: some View {
        RoundedRectangle(cornerRadius: corner, style: .continuous)
            .fill(Theme.cellEmpty)
    }

    @ViewBuilder
    private var ghostOverlay: some View {
        switch ghostState {
        case .none:
            EmptyView()
        case .valid:
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(Theme.good.opacity(0.55))
                .overlay(RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .strokeBorder(Theme.good, lineWidth: 1.5))
        case .invalid:
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(Theme.bad.opacity(0.45))
                .overlay(RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .strokeBorder(Theme.bad, lineWidth: 1.5))
        case .flashing:
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(Color.white.opacity(0.85))
        }
    }
}
