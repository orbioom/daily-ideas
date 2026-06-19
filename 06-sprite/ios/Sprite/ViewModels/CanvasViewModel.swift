import SwiftUI

enum SpriteTool: String, CaseIterable {
    case pen = "pencil"
    case eraser = "eraser"
    case fill = "paintbucket"
    case eyedropper = "eyedropper"
    case move = "arrow.up.and.down.and.arrow.left.and.right"
}

@Observable
final class CanvasViewModel {
    var artwork: SpriteArtwork
    var pixels: [Int]
    var palette: [String]
    var selectedColorIndex: Int = 0
    var selectedTool: SpriteTool = .pen
    var undoStack: [[Int]] = []
    var redoStack: [[Int]] = []
    var zoom: CGFloat = 1.0
    var offset: CGSize = .zero

    init(artwork: SpriteArtwork) {
        self.artwork = artwork
        self.pixels = artwork.loadPixels()
        self.palette = artwork.loadPalette()
        if self.palette.isEmpty {
            self.palette = ["#000000","#FFFFFF","#FF0000","#00FF00","#0000FF","#FFFF00","#FF8800","#8800FF","#FF88AA","#00AAFF","#AAFFAA","#AAAAFF"]
        }
    }

    var currentColor: String { palette[safe: selectedColorIndex] ?? "#000000" }

    func tap(at index: Int) {
        guard index >= 0, index < pixels.count else { return }
        switch selectedTool {
        case .pen:
            pushUndo()
            setPixel(index, color: colorInt(currentColor))
            persist()
        case .eraser:
            pushUndo()
            setPixel(index, color: 0)
            persist()
        case .fill:
            pushUndo()
            floodFill(from: index, with: colorInt(currentColor))
            persist()
        case .eyedropper:
            let existing = pixels[index]
            if existing != 0 {
                let hex = hexString(from: existing)
                if let idx = palette.firstIndex(of: hex) {
                    selectedColorIndex = idx
                } else {
                    palette.append(hex)
                    selectedColorIndex = palette.count - 1
                    artwork.savePalette(palette)
                }
            }
        case .move:
            break
        }
    }

    func drag(at index: Int) {
        guard index >= 0, index < pixels.count else { return }
        switch selectedTool {
        case .pen:
            setPixel(index, color: colorInt(currentColor))
        case .eraser:
            setPixel(index, color: 0)
        default: break
        }
    }

    func endDrag() {
        if selectedTool == .pen || selectedTool == .eraser {
            persist()
        }
    }

    private func setPixel(_ index: Int, color: Int) {
        pixels[index] = color
    }

    private func floodFill(from start: Int, with color: Int) {
        let target = pixels[start]
        guard target != color else { return }
        var stack = [start]
        var visited = Set<Int>()
        let w = artwork.width
        let h = artwork.height
        while !stack.isEmpty {
            let idx = stack.removeLast()
            guard idx >= 0, idx < pixels.count, !visited.contains(idx), pixels[idx] == target else { continue }
            visited.insert(idx)
            pixels[idx] = color
            let r = idx / w
            let c = idx % w
            if c > 0 { stack.append(idx - 1) }
            if c < w - 1 { stack.append(idx + 1) }
            if r > 0 { stack.append(idx - w) }
            if r < h - 1 { stack.append(idx + w) }
        }
    }

    func addColor(_ hex: String) {
        if !palette.contains(hex) {
            palette.append(hex)
            artwork.savePalette(palette)
        }
        selectedColorIndex = palette.firstIndex(of: hex) ?? 0
    }

    func undo() {
        guard let prev = undoStack.popLast() else { return }
        redoStack.append(pixels)
        pixels = prev
        persist()
    }

    func redo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(pixels)
        pixels = next
        persist()
    }

    private func pushUndo() {
        undoStack.append(pixels)
        if undoStack.count > 30 { undoStack.removeFirst() }
        redoStack = []
    }

    func persist() {
        artwork.savePixels(pixels)
    }

    func renderImage() -> UIImage? {
        let w = artwork.width, h = artwork.height
        var data = [UInt8](repeating: 255, count: w * h * 4)
        for i in 0..<pixels.count {
            let c = pixels[i]
            if c == 0 {
                data[i*4+3] = 0
            } else {
                data[i*4] = UInt8((c >> 16) & 0xFF)
                data[i*4+1] = UInt8((c >> 8) & 0xFF)
                data[i*4+2] = UInt8(c & 0xFF)
                data[i*4+3] = UInt8((c >> 24) & 0xFF)
            }
        }
        let cs = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(data: &data, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4, space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue),
              let cg = ctx.makeImage() else { return nil }
        return UIImage(cgImage: cg)
    }

    private func colorInt(_ hex: String) -> Int {
        let h = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        var val: UInt64 = 0
        Scanner(string: h).scanHexInt64(&val)
        return Int(0xFF000000 | val)
    }

    private func hexString(from colorInt: Int) -> String {
        String(format: "#%06X", colorInt & 0xFFFFFF)
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
