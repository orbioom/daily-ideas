import SwiftUI
import PhotosUI

enum StickerTool: String, CaseIterable {
    case erase = "eraser"
    case border = "pencil.circle"
    case shadow = "shadow"
    case background = "paintpalette"
}

@Observable
final class StickerViewModel {
    var sourceImage: UIImage? = nil
    var maskedImage: UIImage? = nil
    var borderColor: Color = .white
    var borderWidth: Double = 12
    var backgroundColor: Color = .clear
    var hasShadow: Bool = true
    var isProcessing: Bool = false
    var errorMessage: String? = nil
    var selectedTool: StickerTool = .border

    var previewImage: UIImage? {
        guard let src = maskedImage ?? sourceImage else { return nil }
        return renderSticker(from: src)
    }

    func loadImage(_ uiImage: UIImage) {
        sourceImage = uiImage
        isProcessing = true
        Task { @MainActor in
            maskedImage = removeBackground(from: uiImage)
            isProcessing = false
        }
    }

    private func removeBackground(from image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return image }
        let size = CGSize(width: cgImage.width, height: cgImage.height)
        guard let provider = cgImage.dataProvider,
              let data = provider.data,
              let ptr = CFDataGetBytePtr(data) else { return image }
        let bytesPerPixel = cgImage.bitsPerPixel / 8
        let bytesPerRow = cgImage.bytesPerRow
        let w = cgImage.width
        let h = cgImage.height

        var outPixels = [UInt8](repeating: 0, count: w * h * 4)
        let bgR = UInt8(255), bgG = UInt8(255), bgB = UInt8(255)
        let threshold: Int = 40

        for y in 0..<h {
            for x in 0..<w {
                let offset = y * bytesPerRow + x * bytesPerPixel
                let r = ptr[offset]
                let g = ptr[offset + 1]
                let b = ptr[offset + 2]
                let a = bytesPerPixel >= 4 ? ptr[offset + 3] : UInt8(255)
                let dr = abs(Int(r) - Int(bgR))
                let dg = abs(Int(g) - Int(bgG))
                let db = abs(Int(b) - Int(bgB))
                let isBackground = dr + dg + db < threshold
                let outIdx = (y * w + x) * 4
                outPixels[outIdx] = r
                outPixels[outIdx + 1] = g
                outPixels[outIdx + 2] = b
                outPixels[outIdx + 3] = isBackground ? 0 : a
            }
        }
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(data: &outPixels, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue),
              let outCG = ctx.makeImage() else { return image }
        return UIImage(cgImage: outCG, scale: image.scale, orientation: image.imageOrientation)
    }

    func renderSticker(from image: UIImage) -> UIImage {
        let padding = CGFloat(borderWidth) + (hasShadow ? 16 : 0)
        let totalSize = CGSize(width: image.size.width + padding * 2, height: image.size.height + padding * 2)
        let renderer = UIGraphicsImageRenderer(size: totalSize)
        return renderer.image { ctx in
            let cgCtx = ctx.cgContext
            if hasShadow {
                cgCtx.setShadow(offset: CGSize(width: 2, height: 4), blur: 8, color: UIColor.black.withAlphaComponent(0.4).cgColor)
            }
            let ui = UIColor(borderColor)
            ui.setFill()
            let borderRect = CGRect(x: padding - borderWidth, y: padding - borderWidth, width: image.size.width + borderWidth * 2, height: image.size.height + borderWidth * 2)
            let borderPath = UIBezierPath(roundedRect: borderRect, cornerRadius: borderWidth * 0.5)
            borderPath.fill()
            cgCtx.setShadow(offset: .zero, blur: 0)
            image.draw(in: CGRect(origin: CGPoint(x: padding, y: padding), size: image.size))
        }
    }

    func exportSticker(name: String, context: ModelContext) {
        guard let preview = previewImage else { return }
        guard let data = preview.pngData() else { return }
        let sticker = SavedSticker(
            name: name,
            imageData: data,
            borderColor: hexString(from: borderColor),
            borderWidth: borderWidth,
            hasShadow: hasShadow
        )
        context.insert(sticker)
        UIImageWriteToSavedPhotosAlbum(preview, nil, nil, nil)
    }

    private func hexString(from color: Color) -> String {
        let ui = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: nil)
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }

    func reset() {
        sourceImage = nil
        maskedImage = nil
        borderColor = .white
        borderWidth = 12
        backgroundColor = .clear
        hasShadow = true
    }
}
