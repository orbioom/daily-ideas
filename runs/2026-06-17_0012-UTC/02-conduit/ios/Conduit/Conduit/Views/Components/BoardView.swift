import SwiftUI

/// Reads the user's persisted grid-line and color-blind preferences without an
/// observable object, so the board redraws when they change via @AppStorage.
private struct BoardPrefs {
    var colorBlind: Bool
    var thickGrid: Bool
    var highlightCompleted: Bool
}

/// The interactive puzzle board. Renders the grid + pipes with a `Canvas` and maps
/// drag points to cells via a bounds-guarded hit test.
struct BoardView: View {
    @Bindable var engine: ConduitEngine
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @AppStorage("colorBlindMode") private var colorBlind: Bool = false
    @AppStorage("thickGrid") private var thickGrid: Bool = false
    @AppStorage("highlightCompleted") private var highlightCompleted: Bool = true
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true

    /// Called whenever the board changes, so the host can autosave / detect a win.
    var onChange: () -> Void = {}

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let n = max(1, engine.size)
            let cellSize = side / CGFloat(n)

            ZStack {
                Canvas { ctx, _ in
                    drawBoard(ctx: ctx, cellSize: cellSize, n: n)
                }
                .frame(width: side, height: side)

                // Endpoint dots + color-blind labels as accessible overlays.
                endpointOverlay(cellSize: cellSize, n: n)
                    .frame(width: side, height: side)

                // Accessibility grid: one element per cell for VoiceOver.
                accessibilityGrid(cellSize: cellSize, n: n)
                    .frame(width: side, height: side)
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .contentShape(Rectangle())
            .gesture(dragGesture(cellSize: cellSize, n: n))
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // MARK: - Drawing

    private func drawBoard(ctx: GraphicsContext, cellSize: CGFloat, n: Int) {
        let full = CGRect(x: 0, y: 0, width: cellSize * CGFloat(n), height: cellSize * CGFloat(n))

        // Board background.
        let boardPath = Path(roundedRect: full, cornerRadius: cellSize * 0.18)
        ctx.fill(boardPath, with: .color(ConduitTheme.boardSurface(scheme)))

        // Cells.
        let inset = cellSize * 0.06
        for r in 0..<n {
            for c in 0..<n {
                let rect = CGRect(
                    x: CGFloat(c) * cellSize + inset,
                    y: CGFloat(r) * cellSize + inset,
                    width: cellSize - inset * 2,
                    height: cellSize - inset * 2
                )
                let cellPath = Path(roundedRect: rect, cornerRadius: cellSize * 0.12)
                ctx.fill(cellPath, with: .color(ConduitTheme.cellSurface(scheme)))
            }
        }

        // Grid hairlines.
        var grid = Path()
        for i in 0...n {
            let pos = CGFloat(i) * cellSize
            grid.move(to: CGPoint(x: pos, y: 0)); grid.addLine(to: CGPoint(x: pos, y: full.height))
            grid.move(to: CGPoint(x: 0, y: pos)); grid.addLine(to: CGPoint(x: full.width, y: pos))
        }
        ctx.stroke(grid, with: .color(thickGrid ? ConduitTheme.gridLineStrong : ConduitTheme.gridLine),
                   lineWidth: thickGrid ? 1.5 : 0.75)

        // Pipes.
        let pipeWidth = cellSize * 0.42
        for pair in engine.puzzle.pairs {
            let cells = engine.path(for: pair.color)
            guard cells.count >= 1 else { continue }
            let connected = engine.isConnected(pair)
            let baseColor = pair.color.color
            let drawColor = (highlightCompleted && connected)
                ? baseColor
                : baseColor.opacity(connected ? 1.0 : 0.92)

            if cells.count >= 2 {
                var line = Path()
                for (idx, cell) in cells.enumerated() {
                    let p = center(of: cell, cellSize: cellSize)
                    if idx == 0 { line.move(to: p) } else { line.addLine(to: p) }
                }
                ctx.stroke(
                    line,
                    with: .color(drawColor),
                    style: StrokeStyle(lineWidth: pipeWidth, lineCap: .round, lineJoin: .round)
                )
            } else if let only = cells.first {
                // A single-cell stub from an endpoint.
                let p = center(of: only, cellSize: cellSize)
                let dot = Path(ellipseIn: CGRect(x: p.x - pipeWidth/2, y: p.y - pipeWidth/2, width: pipeWidth, height: pipeWidth))
                ctx.fill(dot, with: .color(drawColor))
            }

            // Glow on a completed path when highlighting is on.
            if highlightCompleted && connected && cells.count >= 2 {
                var glow = Path()
                for (idx, cell) in cells.enumerated() {
                    let p = center(of: cell, cellSize: cellSize)
                    if idx == 0 { glow.move(to: p) } else { glow.addLine(to: p) }
                }
                ctx.stroke(glow, with: .color(baseColor.opacity(0.25)),
                           style: StrokeStyle(lineWidth: pipeWidth + 6, lineCap: .round, lineJoin: .round))
            }
        }
    }

    private func center(of cell: Cell, cellSize: CGFloat) -> CGPoint {
        CGPoint(x: (CGFloat(cell.c) + 0.5) * cellSize, y: (CGFloat(cell.r) + 0.5) * cellSize)
    }

    // MARK: - Endpoint dots

    private func endpointOverlay(cellSize: CGFloat, n: Int) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(Array(engine.puzzle.endpoints.enumerated()), id: \.offset) { _, ep in
                let p = center(of: ep.cell, cellSize: cellSize)
                let dotSize = cellSize * 0.62
                ZStack {
                    Circle()
                        .fill(ep.color.color)
                        .frame(width: dotSize, height: dotSize)
                        .overlay(
                            Circle().strokeBorder(Color.white.opacity(0.85), lineWidth: cellSize * 0.05)
                        )
                    if colorBlind {
                        Text(ep.color.label)
                            .font(.system(size: dotSize * 0.5, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.black.opacity(0.7))
                    }
                }
                .position(p)
            }
        }
    }

    // MARK: - Accessibility grid

    private func accessibilityGrid(cellSize: CGFloat, n: Int) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(0..<n, id: \.self) { r in
                ForEach(0..<n, id: \.self) { c in
                    let cell = Cell(r, c)
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: cellSize, height: cellSize)
                        .position(x: (CGFloat(c) + 0.5) * cellSize, y: (CGFloat(r) + 0.5) * cellSize)
                        .accessibilityElement()
                        .accessibilityLabel(cellLabel(cell))
                }
            }
        }
        .accessibilityHidden(false)
    }

    private func cellLabel(_ cell: Cell) -> String {
        let pos = "Row \(cell.r + 1), column \(cell.c + 1)"
        if let ep = engine.endpointColor(at: cell) {
            return "\(pos), \(ep.name) endpoint"
        }
        if let owner = engine.color(at: cell) {
            return "\(pos), \(owner.name) pipe"
        }
        return "\(pos), empty"
    }

    // MARK: - Drag

    private func cell(at point: CGPoint, cellSize: CGFloat, n: Int) -> Cell? {
        guard cellSize > 0 else { return nil }
        let c = Int(point.x / cellSize)
        let r = Int(point.y / cellSize)
        guard r >= 0, r < n, c >= 0, c < n else { return nil }
        return Cell(r, c)
    }

    private func dragGesture(cellSize: CGFloat, n: Int) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard let target = cell(at: value.location, cellSize: cellSize, n: n) else { return }
                if engine.activeColor == nil {
                    let beforeConnected = engine.connectedPairs
                    if engine.beginDrag(at: target) {
                        if hapticsEnabled { Haptics.tick() }
                        notifyConnectChange(before: beforeConnected)
                        onChange()
                    }
                } else {
                    let beforeOwner = engine.color(at: target)
                    let beforeConnected = engine.connectedPairs
                    engine.dragMove(to: target)
                    if engine.color(at: target) != beforeOwner, hapticsEnabled {
                        Haptics.tick()
                    }
                    notifyConnectChange(before: beforeConnected)
                    onChange()
                }
            }
            .onEnded { _ in
                engine.endDrag()
                onChange()
            }
    }

    private func notifyConnectChange(before: Int) {
        if engine.connectedPairs > before, hapticsEnabled {
            Haptics.connect()
        }
    }
}
