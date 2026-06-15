import CoreGraphics

/// Converts half-step slot coordinates into on-screen pixel frames, computing a
/// scale that fits the whole board inside the available canvas with depth offset.
struct BoardGeometry {
    let slots: [LayoutSlot]
    let canvas: CGSize

    // Half-step extents of the layout.
    let minX: Int
    let maxX: Int   // exclusive right edge in half-steps (x + 2)
    let minY: Int
    let maxY: Int
    let maxLayer: Int

    let unit: CGFloat        // pixels per half-step
    let originPixel: CGPoint // top-left pixel of the board content
    let tilePixelSize: CGSize

    init(slots: [LayoutSlot], canvas: CGSize) {
        self.slots = slots
        self.canvas = canvas

        let xs = slots.map { $0.x }
        let ys = slots.map { $0.y }
        let layers = slots.map { $0.layer }
        let lowX = xs.min() ?? 0
        let highX = (xs.max() ?? 0) + 2
        let lowY = ys.min() ?? 0
        let highY = (ys.max() ?? 0) + 2
        let topLayer = layers.max() ?? 0

        self.minX = lowX
        self.maxX = highX
        self.minY = lowY
        self.maxY = highY
        self.maxLayer = topLayer

        let widthHalfSteps = CGFloat(max(2, highX - lowX))
        let heightHalfSteps = CGFloat(max(2, highY - lowY))

        // Reserve space for the depth offset of the highest layer.
        let depthPad = CGFloat(topLayer) * TileView.layerOffset + 12
        let usableW = max(40, canvas.width - depthPad - 12)
        let usableH = max(40, canvas.height - depthPad - 12)

        let unitW = usableW / widthHalfSteps
        let unitH = usableH / heightHalfSteps
        let u = max(4, min(unitW, unitH))
        self.unit = u
        self.tilePixelSize = CGSize(width: u * 2, height: u * 2)

        // Center the board content.
        let boardW = widthHalfSteps * u + depthPad
        let boardH = heightHalfSteps * u + depthPad
        let ox = (canvas.width - boardW) / 2
        let oy = (canvas.height - boardH) / 2
        self.originPixel = CGPoint(x: max(0, ox), y: max(0, oy))
    }

    /// Pixel frame (origin + size) for a slot, including its layer depth offset.
    func frame(for slot: LayoutSlot) -> CGRect {
        let x = originPixel.x + CGFloat(slot.x - minX) * unit + CGFloat(slot.layer) * TileView.layerOffset
        let y = originPixel.y + CGFloat(slot.y - minY) * unit - CGFloat(slot.layer) * TileView.layerOffset
        return CGRect(x: x, y: y, width: tilePixelSize.width, height: tilePixelSize.height)
    }

    /// Drawing order: lower layers first; within a layer, top-to-bottom then
    /// left-to-right so overlaps look right and higher tiles paint over lower.
    func sortedDrawOrder(_ tiles: [PlacedTile]) -> [PlacedTile] {
        tiles.sorted { a, b in
            let sa = slots[safe: a.slotIndex]
            let sb = slots[safe: b.slotIndex]
            guard let sa, let sb else { return false }
            if sa.layer != sb.layer { return sa.layer < sb.layer }
            if sa.y != sb.y { return sa.y < sb.y }
            return sa.x < sb.x
        }
    }
}
