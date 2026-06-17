import CoreGraphics
import Foundation

/// Output aspect ratios the studio can target.
enum AspectRatioOption: String, CaseIterable, Identifiable, Codable {
    case phone = "iPhone"
    case square = "Square"
    case pad = "iPad"

    var id: String { rawValue }

    /// width / height
    var ratio: CGFloat {
        switch self {
        case .phone: return 9.0 / 19.5
        case .square: return 1
        case .pad: return 3.0 / 4.0
        }
    }

    /// High-resolution export pixel size.
    var exportSize: CGSize {
        switch self {
        case .phone: return CGSize(width: 1170, height: 2532)
        case .square: return CGSize(width: 2048, height: 2048)
        case .pad: return CGSize(width: 2048, height: 2732)
        }
    }

    /// Pro-tier 4K export size.
    var exportSizeHighRes: CGSize {
        switch self {
        case .phone: return CGSize(width: 1620, height: 3510)
        case .square: return CGSize(width: 3072, height: 3072)
        case .pad: return CGSize(width: 3072, height: 4098)
        }
    }
}
