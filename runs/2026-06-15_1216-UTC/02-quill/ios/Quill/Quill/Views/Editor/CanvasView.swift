import PencilKit
import SwiftUI

/// SwiftUI wrapper around `PKCanvasView`. The canvas is transparent so the
/// paper template renders behind it. Drawing changes are debounced and pushed
/// back through `onDrawingChange`.
struct CanvasView: UIViewRepresentable {
    /// Serialized drawing data, two-way bound to the owning view.
    @Binding var drawingData: Data
    /// The currently selected tool.
    let tool: PKTool
    /// Finger + pencil, or pencil only.
    let drawingPolicy: PKCanvasViewDrawingPolicy
    /// Whether the canvas accepts input (e.g. disabled while a sheet is open).
    let isInteractive: Bool

    /// Called (debounced) with fresh serialized data after edits settle.
    var onDrawingChange: (Data) -> Void
    /// Hands the live canvas back so the toolbar can drive undo/redo/clear.
    var onCanvasReady: (PKCanvasView) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.delegate = context.coordinator
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.drawingPolicy = drawingPolicy
        canvas.alwaysBounceVertical = false
        canvas.alwaysBounceHorizontal = false
        canvas.tool = tool
        canvas.contentInsetAdjustmentBehavior = .never

        // Load the existing drawing — guarded, never try!.
        if !drawingData.isEmpty, let drawing = try? PKDrawing(data: drawingData) {
            canvas.drawing = drawing
        }
        context.coordinator.lastLoadedData = drawingData

        // Provide the canvas to the owner on the next runloop tick.
        DispatchQueue.main.async {
            onCanvasReady(canvas)
        }
        return canvas
    }

    func updateUIView(_ canvas: PKCanvasView, context: Context) {
        canvas.tool = tool
        canvas.drawingPolicy = drawingPolicy
        canvas.isUserInteractionEnabled = isInteractive

        // Reload only when the page actually changed underneath us
        // (e.g. navigating to a different page), not on our own writes.
        if drawingData != context.coordinator.lastLoadedData {
            if drawingData.isEmpty {
                canvas.drawing = PKDrawing()
            } else if let drawing = try? PKDrawing(data: drawingData) {
                canvas.drawing = drawing
            }
            context.coordinator.lastLoadedData = drawingData
        }
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        let parent: CanvasView
        var lastLoadedData: Data = Data()
        private var debounceWork: DispatchWorkItem?

        init(parent: CanvasView) {
            self.parent = parent
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            // Debounce writes so rapid strokes don't thrash persistence.
            debounceWork?.cancel()
            let data = canvasView.drawing.dataRepresentation()
            let work = DispatchWorkItem { [weak self] in
                self?.lastLoadedData = data
                self?.parent.onDrawingChange(data)
            }
            debounceWork = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: work)
        }
    }
}
