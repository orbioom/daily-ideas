import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

/// Maps a card's `BarcodeFormat` + raw value to a rendered, crisp barcode image.
///
/// - 1-D Core Image symbologies (Code 128, PDF417) and 2-D (QR, Aztec) are produced
///   with the built-in `CIFilter` generators, then scaled by an *integer* factor with
///   nearest-neighbor sampling so bars stay razor-sharp instead of blurry.
/// - EAN-13 / UPC-A are drawn from our hand-rolled module pattern (see `EAN13Encoder`)
///   by the dedicated `EAN13BarcodeView`, so the factory only validates those here.
enum BarcodeFactory {

    /// A shared Core Image context. Cheap to keep around; avoids per-call allocation.
    private static let context = CIContext(options: [.useSoftwareRenderer: false])

    /// Validate a value for a format. Returns the normalized string to encode, or a
    /// calm error. For EAN-13 / UPC-A the normalized string is the full 13-digit form.
    static func validate(_ value: String, format: BarcodeFormat) -> Result<String, BarcodeError> {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .failure(.empty) }

        switch format {
        case .ean13:
            return EAN13Encoder.normalizedEAN13(from: trimmed)
        case .upca:
            return EAN13Encoder.normalizedUPCA(from: trimmed)
        case .code128, .qr, .aztec, .pdf417:
            return .success(trimmed)
        }
    }

    /// Render a Core-Image-backed barcode for the given value & format into a `UIImage`.
    /// Returns `nil` for EAN-13 / UPC-A (handled by the Canvas view) or on failure.
    static func coreImage(for value: String, format: BarcodeFormat, scale: Int = 10) -> UIImage? {
        guard case .success(let normalized) = validate(value, format: format) else { return nil }
        guard let data = normalized.data(using: .ascii) ?? normalized.data(using: .utf8) else {
            return nil
        }

        let output: CIImage?
        switch format {
        case .code128:
            let filter = CIFilter.code128BarcodeGenerator()
            filter.message = data
            filter.quietSpace = 8
            output = filter.outputImage
        case .qr:
            let filter = CIFilter.qrCodeGenerator()
            filter.message = data
            filter.correctionLevel = "M"
            output = filter.outputImage
        case .aztec:
            let filter = CIFilter.aztecCodeGenerator()
            filter.message = data
            filter.correctionLevel = 23
            output = filter.outputImage
        case .pdf417:
            let filter = CIFilter.pdf417BarcodeGenerator()
            filter.message = data
            output = filter.outputImage
        case .ean13, .upca:
            return nil
        }

        guard let ciImage = output else { return nil }

        // Integer scale + nearest-neighbor (CISampleNearest) keeps edges crisp.
        let scaleValue = CGFloat(max(1, scale))
        let scaled = ciImage
            .samplingNearest()
            .transformed(by: CGAffineTransform(scaleX: scaleValue, y: scaleValue))

        guard let cg = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cg)
    }

    /// A human-readable, formatted version of the underlying value for display under a
    /// barcode (e.g. grouped EAN digits). Falls back to the raw value.
    static func displayValue(for value: String, format: BarcodeFormat) -> String {
        switch format {
        case .ean13:
            if case .success(let n) = EAN13Encoder.normalizedEAN13(from: value), n.count == 13 {
                // Group as 1 6 6 like printed EAN-13.
                let chars = Array(n)
                let a = String(chars[0])
                let b = String(chars[1...6])
                let c = String(chars[7...12])
                return "\(a) \(b) \(c)"
            }
            return value
        case .upca:
            if case .success(let n) = EAN13Encoder.normalizedUPCA(from: value), n.count == 13 {
                // Strip the EAN leading 0 to show the 12-digit UPC-A.
                let upc = String(n.dropFirst())
                let chars = Array(upc)
                guard chars.count == 12 else { return upc }
                let a = String(chars[0])
                let b = String(chars[1...5])
                let c = String(chars[6...10])
                let d = String(chars[11])
                return "\(a) \(b) \(c) \(d)"
            }
            return value
        default:
            return value
        }
    }
}
