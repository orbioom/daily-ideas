import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit
import SwiftUI

enum CorrectionLevel: String, CaseIterable, Identifiable {
    case low = "L"
    case medium = "M"
    case quartile = "Q"
    case high = "H"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .low: return "Low (7%)"
        case .medium: return "Medium (15%)"
        case .quartile: return "Quartile (25%)"
        case .high: return "High (30%)"
        }
    }
}

/// On-device QR generation via CoreImage. No network, no expiring links —
/// the code IS the data.
enum QRRenderer {
    private static let context = CIContext()

    /// Renders a crisp QR image. With `scale == nil` the module size is chosen
    /// so the longest edge lands near 1024 px — sharp enough to print or share.
    static func image(
        for payload: String,
        correction: CorrectionLevel,
        foreground: UIColor,
        background: UIColor,
        scale: CGFloat? = nil
    ) -> UIImage? {
        guard !payload.isEmpty, let data = payload.data(using: .utf8) else { return nil }
        let filter = CIFilter.qrCodeGenerator()
        filter.message = data
        filter.correctionLevel = correction.rawValue
        guard let output = filter.outputImage else { return nil }

        // Tint modules + background.
        let colored = output.applyingFilter("CIFalseColor", parameters: [
            "inputColor0": CIColor(color: foreground),
            "inputColor1": CIColor(color: background),
        ])

        let edge = max(colored.extent.width, 1)
        let effectiveScale = scale ?? max(1, (1024.0 / edge).rounded(.down))
        let transformed = colored.transformed(by: CGAffineTransform(scaleX: effectiveScale, y: effectiveScale))
        guard let cgImage = context.createCGImage(transformed, from: transformed.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    /// PNG data for sharing/export at the auto-chosen ~1024-pixel edge.
    static func pngData(
        for payload: String,
        correction: CorrectionLevel,
        foreground: UIColor,
        background: UIColor
    ) -> Data? {
        image(for: payload, correction: correction, foreground: foreground, background: background)?.pngData()
    }
}

// MARK: - Hex color helpers (asset-free custom colors that survive Codable)

extension UIColor {
    convenience init(hex: String) {
        var value: UInt64 = 0
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        Scanner(string: cleaned).scanHexInt64(&value)
        let r = CGFloat((value >> 16) & 0xFF) / 255.0
        let g = CGFloat((value >> 8) & 0xFF) / 255.0
        let b = CGFloat(value & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: 1)
    }

    var hexString: String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        func clamp(_ v: CGFloat) -> Int { min(255, max(0, Int((v * 255).rounded()))) }
        return String(format: "%02X%02X%02X", clamp(r), clamp(g), clamp(b))
    }
}

extension Color {
    init(hex: String) {
        self.init(uiColor: UIColor(hex: hex))
    }
}
