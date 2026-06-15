import SwiftUI

/// Hosts the page canvas with pinch-zoom + pan and maps taps back to normalized
/// page coordinates for hit-testing. The page renders in a centered square.
struct ZoomableCanvas: View {
    @ObservedObject var model: ColoringViewModel
    var showOutlines: Bool
    var hapticsEnabled: Bool

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    private let minScale: CGFloat = 1
    private let maxScale: CGFloat = 5

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let squareOrigin = CGPoint(x: (geo.size.width - side) / 2,
                                       y: (geo.size.height - side) / 2)

            ZStack {
                PageCanvasView(page: model.page,
                               fills: model.fills,
                               palette: model.palette,
                               showOutlines: showOutlines,
                               showNumbers: model.byNumberMode,
                               highlightedRegion: model.highlightedRegion)
                    .frame(width: geo.size.width, height: geo.size.height)
            }
            .scaleEffect(scale)
            .offset(offset)
            .contentShape(Rectangle())
            .gesture(
                // minimumDistance 0 so a tap is recognized; we treat a near-zero
                // translation drag as a tap-to-fill, otherwise as a pan.
                DragGesture(minimumDistance: 0, coordinateSpace: .named("hueCanvas"))
                    .onChanged { v in
                        guard scale > 1 else { return }
                        let dx = v.translation.width
                        let dy = v.translation.height
                        if dx * dx + dy * dy > 100 { // moved > 10pt -> treat as pan
                            offset = CGSize(width: lastOffset.width + dx,
                                            height: lastOffset.height + dy)
                        }
                    }
                    .onEnded { v in
                        let dx = v.translation.width
                        let dy = v.translation.height
                        if dx * dx + dy * dy <= 100 {
                            // A tap.
                            handleTap(at: v.location, geo: geo, side: side, origin: squareOrigin)
                        } else if scale > 1 {
                            lastOffset = offset
                        }
                    }
            )
            .simultaneousGesture(
                MagnificationGesture()
                    .onChanged { v in
                        scale = min(max(lastScale * v, minScale), maxScale)
                    }
                    .onEnded { _ in
                        lastScale = scale
                        if scale <= 1 { offset = .zero; lastOffset = .zero }
                    }
            )
            .accessibilityElement()
            .accessibilityLabel("\(model.page.title) coloring page")
            .accessibilityValue("\(Int(model.progress * 100)) percent filled. Double tap the more menu for an accessible region list.")
            .accessibilityHint("Pinch to zoom, drag to pan. Tap a region to fill it with the selected color.")
            .overlay(alignment: .bottomTrailing) {
                if scale > 1.01 {
                    Button {
                        resetZoom()
                    } label: {
                        Image(systemName: "arrow.down.right.and.arrow.up.left")
                            .font(.system(size: 14, weight: .semibold))
                            .padding(10)
                            .background(Circle().fill(Theme.surface))
                            .overlay(Circle().strokeBorder(Theme.hairline))
                    }
                    .padding(12)
                    .accessibilityLabel("Reset zoom")
                }
            }
        }
        .coordinateSpace(name: "hueCanvas")
        .background(
            RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                .fill(Color(hex: 0xFFFFFF))
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                .strokeBorder(Theme.hairline, lineWidth: 1)
        )
    }

    private func resetZoom() {
        withAnimation(.easeInOut(duration: 0.2)) {
            scale = 1; lastScale = 1; offset = .zero; lastOffset = .zero
        }
    }

    /// Convert a tap (in the view's coordinate space) to normalized page space,
    /// accounting for the current scale/offset and the centered square.
    private func handleTap(at location: CGPoint, geo: GeometryProxy, side: CGFloat, origin: CGPoint) {
        let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
        // Undo the scaleEffect (anchored at center) and the offset.
        let x = (location.x - offset.width - center.x) / scale + center.x
        let y = (location.y - offset.height - center.y) / scale + center.y
        // Now map into the centered square's normalized space.
        guard side > 0 else { return }
        let nx = (x - origin.x) / side
        let ny = (y - origin.y) / side
        guard nx >= 0, nx <= 1, ny >= 0, ny <= 1 else { return }
        model.handleTap(atNormalized: CGPoint(x: nx, y: ny), hapticsEnabled: hapticsEnabled)
    }
}
