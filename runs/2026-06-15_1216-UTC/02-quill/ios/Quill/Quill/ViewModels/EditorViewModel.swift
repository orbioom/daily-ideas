import PencilKit
import SwiftUI

/// Drives the page editor: current tool, color, width, the live canvas handle,
/// and thumbnail generation. Tool configuration is held here so it persists as
/// the user pages through a notebook.
@MainActor
final class EditorViewModel: ObservableObject {
    @Published var toolKind: ToolKind = .pen
    @Published var inkColorHex: UInt = 0x1E1B2E
    @Published var width: CGFloat = ToolKind.pen.defaultWidth
    @Published private(set) var canUndo = false
    @Published private(set) var canRedo = false

    /// The live canvas, set once `CanvasView` is ready.
    weak var canvas: PKCanvasView?

    /// The composed PencilKit tool for the current selection.
    var currentTool: PKTool {
        toolKind.makeTool(color: UIColor(hex: inkColorHex), width: width)
    }

    /// Seed the initial color from the user's default pen color.
    func configureInitialColor(from hexString: String) {
        let scrubbed = hexString.trimmingCharacters(in: CharacterSet(charactersIn: "# "))
        if let value = UInt(scrubbed, radix: 16), scrubbed.count == 6 {
            inkColorHex = value
        }
    }

    func select(_ kind: ToolKind) {
        toolKind = kind
        if kind.isInking {
            // Clamp width into the new tool's range.
            let range = kind.widthRange
            if !range.contains(width) {
                width = kind.defaultWidth
            }
        }
        refreshUndoState()
    }

    func setColor(_ hex: UInt) {
        inkColorHex = hex
    }

    func attach(_ canvas: PKCanvasView) {
        self.canvas = canvas
        refreshUndoState()
    }

    func undo() {
        canvas?.undoManager?.undo()
        refreshUndoState()
    }

    func redo() {
        canvas?.undoManager?.redo()
        refreshUndoState()
    }

    func clear() {
        canvas?.drawing = PKDrawing()
        refreshUndoState()
    }

    func refreshUndoState() {
        canUndo = canvas?.undoManager?.canUndo ?? false
        canRedo = canvas?.undoManager?.canRedo ?? false
    }
}
