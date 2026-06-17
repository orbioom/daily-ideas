import SwiftUI

/// The circular letter wheel. Supports tapping letters in sequence or dragging
/// across them; a connecting line traces the current selection. Reports
/// lifecycle events to the parent which owns the GameModel.
struct LetterWheelView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let letters: [WheelLetter]
    let selection: [Int]

    let onBegin: (Int) -> Void
    let onExtend: (Int) -> Void
    let onTap: (Int) -> Void
    let onRelease: () -> Void

    @State private var slotCenters: [Int: CGPoint] = [:]
    @State private var dragLocation: CGPoint? = nil
    @State private var isDragging = false

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let radius = size * 0.36
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let tile = max(40, min(size * 0.2, 64))

            ZStack {
                Circle()
                    .fill(Theme.surface)
                    .overlay(Circle().strokeBorder(Theme.hairline, lineWidth: 1.5))
                    .frame(width: size, height: size)
                    .position(center)
                    .shadow(color: Theme.accent.opacity(0.08), radius: 12, y: 4)

                // Connecting line for the active selection.
                SelectionLine(points: selectionPoints(dragLocation: dragLocation))
                    .stroke(Theme.accent.opacity(0.6), style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))

                ForEach(Array(letters.enumerated()), id: \.element.id) { idx, item in
                    let pos = position(for: idx, total: letters.count, center: center, radius: radius)
                    let isSelected = selection.contains(item.slot)
                    let order = (selection.firstIndex(of: item.slot)).map { $0 + 1 }
                    WheelTile(letter: item.letter, selected: isSelected, order: order, side: tile,
                              reduceMotion: reduceMotion)
                        .position(pos)
                        .onTapGesture { onTap(item.slot) }
                        .accessibilityLabel("Letter \(String(item.letter))")
                        .accessibilityValue(isSelected ? "selected, position \(order ?? 0)" : "not selected")
                        .accessibilityHint("Double tap to add this letter to your word")
                        .accessibilityAddTraits(.isButton)
                        .background(
                            GeometryReader { tileGeo -> Color in
                                let frame = tileGeo.frame(in: .named("wheel"))
                                let c = CGPoint(x: frame.midX, y: frame.midY)
                                DispatchQueue.main.async { slotCenters[item.slot] = c }
                                return Color.clear
                            }
                        )
                }
            }
            .coordinateSpace(name: "wheel")
            .contentShape(Circle())
            .gesture(dragGesture(tile: tile))
        }
    }

    private func dragGesture(tile: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 4, coordinateSpace: .named("wheel"))
            .onChanged { value in
                dragLocation = value.location
                if let slot = nearestSlot(to: value.location, within: tile * 0.7) {
                    if !isDragging {
                        isDragging = true
                        onBegin(slot)
                    } else {
                        onExtend(slot)
                    }
                }
            }
            .onEnded { _ in
                dragLocation = nil
                if isDragging {
                    isDragging = false
                    onRelease()
                }
            }
    }

    private func nearestSlot(to point: CGPoint, within distance: CGFloat) -> Int? {
        var best: Int? = nil
        var bestDist = distance
        for (slot, c) in slotCenters {
            let d = hypot(c.x - point.x, c.y - point.y)
            if d < bestDist {
                bestDist = d
                best = slot
            }
        }
        return best
    }

    private func selectionPoints(dragLocation: CGPoint?) -> [CGPoint] {
        var pts = selection.compactMap { slotCenters[$0] }
        if isDragging, let drag = dragLocation, !pts.isEmpty {
            pts.append(drag)
        }
        return pts
    }

    private func position(for index: Int, total: Int, center: CGPoint, radius: CGFloat) -> CGPoint {
        guard total > 0 else { return center }
        let angle = (Double(index) / Double(total)) * 2 * .pi - .pi / 2
        return CGPoint(
            x: center.x + radius * cos(angle),
            y: center.y + radius * sin(angle)
        )
    }
}

private struct WheelTile: View {
    let letter: Character
    let selected: Bool
    let order: Int?
    let side: CGFloat
    let reduceMotion: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(selected ? AnyShapeStyle(Theme.heroGradient) : AnyShapeStyle(Theme.surfaceSunken))
                .overlay(Circle().strokeBorder(selected ? Color.clear : Theme.hairline, lineWidth: 1.5))
            Text(String(letter))
                .font(Theme.rounded(side * 0.5, .heavy))
                .foregroundStyle(selected ? .white : Theme.ink)
                .minimumScaleFactor(0.5)
        }
        .frame(width: side, height: side)
        .scaleEffect(selected && !reduceMotion ? 1.12 : 1.0)
        .animation(reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.6), value: selected)
    }
}

private struct SelectionLine: Shape {
    let points: [CGPoint]
    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)
        for p in points.dropFirst() { path.addLine(to: p) }
        return path
    }
}
