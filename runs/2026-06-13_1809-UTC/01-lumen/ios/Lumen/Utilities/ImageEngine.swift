import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

/// Shared Core Image renderer plus small image helpers.
final class ImageEngine {
    static let shared = ImageEngine()
    let context = CIContext(options: [.cacheIntermediates: false])

    private init() {}

    func render(_ image: CIImage) -> UIImage? {
        let rect = image.extent.isInfinite ? CGRect(x: 0, y: 0, width: 1024, height: 1024) : image.extent
        guard let cg = context.createCGImage(image, from: rect) else { return nil }
        return UIImage(cgImage: cg)
    }

    func processed(source: CIImage, adjustments: Adjustments) -> UIImage? {
        render(adjustments.apply(to: source))
    }

    /// Lanczos downscale so the live preview stays smooth on big photos.
    func downscaled(_ ci: CIImage, maxDimension: CGFloat) -> CIImage {
        let extent = ci.extent
        let longest = max(extent.width, extent.height)
        guard longest > maxDimension, longest > 0 else { return ci }
        let scale = maxDimension / longest
        let f = CIFilter.lanczosScaleTransform()
        f.inputImage = ci; f.scale = Float(scale); f.aspectRatio = 1
        return f.outputImage ?? ci
    }

    /// A drawn stand-in photo used to preview presets in the Looks gallery.
    func sampleImage(size: CGFloat = 600) -> CIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        let img = renderer.image { ctx in
            let c = ctx.cgContext
            // Sky gradient
            let colors = [UIColor(red: 0.95, green: 0.72, blue: 0.45, alpha: 1).cgColor,
                          UIColor(red: 0.86, green: 0.45, blue: 0.42, alpha: 1).cgColor,
                          UIColor(red: 0.36, green: 0.30, blue: 0.52, alpha: 1).cgColor]
            if let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                     colors: colors as CFArray, locations: [0, 0.5, 1]) {
                c.drawLinearGradient(grad, start: .zero, end: CGPoint(x: 0, y: size), options: [])
            }
            // Sun
            c.setFillColor(UIColor(white: 1, alpha: 0.92).cgColor)
            c.fillEllipse(in: CGRect(x: size * 0.62, y: size * 0.18, width: size * 0.2, height: size * 0.2))
            // Hills
            c.setFillColor(UIColor(red: 0.18, green: 0.22, blue: 0.30, alpha: 1).cgColor)
            c.beginPath()
            c.move(to: CGPoint(x: 0, y: size))
            c.addLine(to: CGPoint(x: 0, y: size * 0.74))
            c.addQuadCurve(to: CGPoint(x: size * 0.5, y: size * 0.82), control: CGPoint(x: size * 0.25, y: size * 0.66))
            c.addQuadCurve(to: CGPoint(x: size, y: size * 0.72), control: CGPoint(x: size * 0.75, y: size * 0.9))
            c.addLine(to: CGPoint(x: size, y: size))
            c.closePath(); c.fillPath()
        }
        return CIImage(image: img) ?? CIImage(color: .gray).cropped(to: CGRect(x: 0, y: 0, width: size, height: size))
    }

    func thumbnailData(from image: UIImage, maxDimension: CGFloat = 320) -> Data {
        let size = image.size
        let longest = max(size.width, size.height)
        let scale = longest > maxDimension ? maxDimension / longest : 1
        let target = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: target)
        let resized = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: target)) }
        return resized.jpegData(compressionQuality: 0.7) ?? Data()
    }
}
