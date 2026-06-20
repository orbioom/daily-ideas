import SwiftUI

struct GameCanvasView: View {
    let game: RampartGame

    private let gameWidth: Double = 320
    private let gameHeight: Double = 480
    private let cellSize: Double = 20

    var body: some View {
        GeometryReader { geo in
            Canvas { ctx, size in
                let scaleX = size.width / gameWidth
                let scaleY = size.height / gameHeight

                drawCells(ctx: ctx, scaleX: scaleX, scaleY: scaleY)
                drawPathLine(ctx: ctx, scaleX: scaleX, scaleY: scaleY)
                drawSelectionHighlight(ctx: ctx, scaleX: scaleX, scaleY: scaleY)
                drawTowers(ctx: ctx, scaleX: scaleX, scaleY: scaleY)
                drawRangeIndicator(ctx: ctx, scaleX: scaleX, scaleY: scaleY)
                drawProjectiles(ctx: ctx, scaleX: scaleX, scaleY: scaleY)
                drawEnemies(ctx: ctx, scaleX: scaleX, scaleY: scaleY)
            }
        }
    }

    private func scaled(_ p: CGPoint, sx: Double, sy: Double) -> CGPoint {
        CGPoint(x: p.x * sx, y: p.y * sy)
    }

    private func drawCells(ctx: GraphicsContext, scaleX: Double, scaleY: Double) {
        let rows = game.map.cells.count
        for row in 0..<rows {
            let cols = game.map.cells[row].count
            for col in 0..<cols {
                let cell = game.map.cells[row][col]
                let rect = CGRect(
                    x: Double(col) * cellSize * scaleX,
                    y: Double(row) * cellSize * scaleY,
                    width: cellSize * scaleX,
                    height: cellSize * scaleY
                )
                let fillColor: Color = cell.isPath
                    ? Color(red: 0.38, green: 0.36, blue: 0.30)
                    : Color(red: 0.16, green: 0.22, blue: 0.14)
                ctx.fill(Path(rect), with: .color(fillColor))
                ctx.stroke(Path(rect), with: .color(Color.black.opacity(0.25)), lineWidth: 0.5)
            }
        }
    }

    private func drawPathLine(ctx: GraphicsContext, scaleX: Double, scaleY: Double) {
        let path = game.map.path
        guard path.count >= 2 else { return }
        var pathShape = Path()
        pathShape.move(to: scaled(path[0], sx: scaleX, sy: scaleY))
        for pt in path.dropFirst() {
            pathShape.addLine(to: scaled(pt, sx: scaleX, sy: scaleY))
        }
        ctx.stroke(pathShape, with: .color(Color.white.opacity(0.12)), lineWidth: 2.0 * min(scaleX, scaleY))
    }

    private func drawSelectionHighlight(ctx: GraphicsContext, scaleX: Double, scaleY: Double) {
        guard let sel = game.selectedCell else { return }
        let rect = CGRect(
            x: Double(sel.col) * cellSize * scaleX,
            y: Double(sel.row) * cellSize * scaleY,
            width: cellSize * scaleX,
            height: cellSize * scaleY
        )
        ctx.fill(Path(rect), with: .color(Color.yellow.opacity(0.3)))
        ctx.stroke(Path(rect), with: .color(Color.yellow.opacity(0.8)), lineWidth: 1.5)
    }

    private func drawRangeIndicator(ctx: GraphicsContext, scaleX: Double, scaleY: Double) {
        guard let sel = game.selectedCell else { return }
        guard game.hasTower(at: sel) == nil else { return }
        let center = CGPoint(
            x: (Double(sel.col) * cellSize + cellSize / 2) * scaleX,
            y: (Double(sel.row) * cellSize + cellSize / 2) * scaleY
        )
        let radius = game.selectedTowerType.range * min(scaleX, scaleY)
        let rangeRect = CGRect(
            x: center.x - radius,
            y: center.y - radius,
            width: radius * 2,
            height: radius * 2
        )
        ctx.fill(Path(ellipseIn: rangeRect), with: .color(game.selectedTowerType.color.opacity(0.15)))
        ctx.stroke(Path(ellipseIn: rangeRect), with: .color(game.selectedTowerType.color.opacity(0.5)), lineWidth: 1.0)
    }

    private func drawTowers(ctx: GraphicsContext, scaleX: Double, scaleY: Double) {
        for tower in game.towers {
            let cx = tower.position.x * scaleX
            let cy = tower.position.y * scaleY
            let r = 8.0 * min(scaleX, scaleY)
            let outerRect = CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)
            ctx.fill(Path(ellipseIn: outerRect), with: .color(tower.type.color))
            ctx.stroke(Path(ellipseIn: outerRect), with: .color(Color.white.opacity(0.8)), lineWidth: 1.0)

            // Draw tower symbol
            let symbol: String
            switch tower.type {
            case .archer: symbol = "🏹"
            case .cannon: symbol = "💣"
            case .frost: symbol = "❄️"
            }
            let fontSize = 9.0 * min(scaleX, scaleY)
            ctx.draw(
                Text(symbol).font(.system(size: fontSize)),
                at: CGPoint(x: cx, y: cy),
                anchor: .center
            )
        }
    }

    private func drawProjectiles(ctx: GraphicsContext, scaleX: Double, scaleY: Double) {
        for proj in game.projectiles {
            let cx = proj.position.x * scaleX
            let cy = proj.position.y * scaleY
            let r = 3.0 * min(scaleX, scaleY)
            let rect = CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)
            let color: Color
            switch proj.type {
            case .archer: color = .yellow
            case .cannon: color = Color(red: 0.8, green: 0.4, blue: 0.1)
            case .frost: color = Color(red: 0.5, green: 0.8, blue: 1.0)
            }
            ctx.fill(Path(ellipseIn: rect), with: .color(color))
        }
    }

    private func drawEnemies(ctx: GraphicsContext, scaleX: Double, scaleY: Double) {
        for enemy in game.enemies {
            let cx = enemy.position.x * scaleX
            let cy = enemy.position.y * scaleY
            let r = (enemy.type.size / 2) * min(scaleX, scaleY)
            let rect = CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)

            let baseColor = Color(red: 0.75, green: 0.22, blue: 0.17)
            let fillColor = enemy.frosted ? Color(red: 0.4, green: 0.7, blue: 1.0) : baseColor
            ctx.fill(Path(ellipseIn: rect), with: .color(fillColor))
            ctx.stroke(Path(ellipseIn: rect), with: .color(Color.white.opacity(0.6)), lineWidth: 0.8)

            // Emoji
            let fontSize = max(8.0, r * 1.2)
            ctx.draw(
                Text(enemy.type.emoji).font(.system(size: fontSize)),
                at: CGPoint(x: cx, y: cy),
                anchor: .center
            )

            // HP bar
            let hpRatio = max(0, enemy.hp / enemy.maxHp)
            let barWidth = r * 2.5
            let barHeight = 3.0 * min(scaleX, scaleY)
            let barY = cy - r - barHeight - 2.0 * min(scaleX, scaleY)
            let bgBar = CGRect(x: cx - barWidth / 2, y: barY, width: barWidth, height: barHeight)
            ctx.fill(Path(bgBar), with: .color(Color.black.opacity(0.6)))
            let hpBar = CGRect(x: cx - barWidth / 2, y: barY, width: barWidth * hpRatio, height: barHeight)
            let hpColor: Color = hpRatio > 0.5 ? .green : (hpRatio > 0.25 ? .yellow : .red)
            ctx.fill(Path(hpBar), with: .color(hpColor))
        }
    }
}
