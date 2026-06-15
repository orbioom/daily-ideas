import PencilKit
import SwiftUI

/// The selectable tools surfaced in Quill's custom toolbar.
enum ToolKind: String, CaseIterable, Identifiable {
    case pen
    case marker
    case fountain
    case eraserVector
    case eraserBitmap

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pen: return "Pen"
        case .marker: return "Highlighter"
        case .fountain: return "Fountain Pen"
        case .eraserVector: return "Object Eraser"
        case .eraserBitmap: return "Pixel Eraser"
        }
    }

    var systemImage: String {
        switch self {
        case .pen: return "pencil.tip"
        case .marker: return "highlighter"
        case .fountain: return "pencil.and.outline"
        case .eraserVector: return "eraser"
        case .eraserBitmap: return "eraser.line.dashed"
        }
    }

    var isEraser: Bool {
        self == .eraserVector || self == .eraserBitmap
    }

    var isInking: Bool { !isEraser }

    /// The default stroke width for inking tools.
    var defaultWidth: CGFloat {
        switch self {
        case .pen: return 4
        case .marker: return 18
        case .fountain: return 6
        case .eraserVector, .eraserBitmap: return 20
        }
    }

    /// Allowable width range for the stepper.
    var widthRange: ClosedRange<CGFloat> {
        switch self {
        case .pen: return 1...20
        case .marker: return 8...40
        case .fountain: return 2...24
        case .eraserVector, .eraserBitmap: return 8...60
        }
    }

    /// Maps to a concrete PencilKit tool.
    func makeTool(color: UIColor, width: CGFloat) -> PKTool {
        switch self {
        case .pen:
            return PKInkingTool(.pen, color: color, width: width)
        case .marker:
            return PKInkingTool(.marker, color: color, width: width)
        case .fountain:
            return PKInkingTool(.fountainPen, color: color, width: width)
        case .eraserVector:
            return PKEraserTool(.vector)
        case .eraserBitmap:
            return PKEraserTool(.bitmap)
        }
    }
}
