import SwiftUI
import UIKit

struct BackgroundStyle: Identifiable, Hashable {
    let id: String
    let name: String
    let colors: [UInt]        // 1 = solid, 2 = gradient
    let isPro: Bool

    var isGradient: Bool { colors.count > 1 }
    var swiftUIColors: [Color] { colors.map { Color(hex: $0) } }

    static func == (l: BackgroundStyle, r: BackgroundStyle) -> Bool { l.id == r.id }
    func hash(into h: inout Hasher) { h.combine(id) }

    @ViewBuilder var fill: some View {
        if isGradient {
            LinearGradient(colors: swiftUIColors, startPoint: .topLeading, endPoint: .bottomTrailing)
        } else {
            swiftUIColors.first ?? Color.black
        }
    }
}

enum BackgroundLibrary {
    static let all: [BackgroundStyle] = [
        .init(id: "white", name: "White", colors: [0xFFFFFF], isPro: false),
        .init(id: "ink", name: "Ink", colors: [0x14141A], isPro: false),
        .init(id: "cream", name: "Cream", colors: [0xF5EFE6], isPro: false),
        .init(id: "blush", name: "Blush", colors: [0xF7D9E3], isPro: false),
        .init(id: "sky", name: "Sky", colors: [0xCDE3F5], isPro: false),
        .init(id: "sage", name: "Sage", colors: [0xD7E3D2], isPro: false),
        .init(id: "sunset", name: "Sunset", colors: [0xFF9A6B, 0xE0467C], isPro: false),
        .init(id: "peachy", name: "Peachy", colors: [0xFFD9A0, 0xF6928C], isPro: false),
        .init(id: "grape", name: "Grape", colors: [0x8A5CF0, 0xE0467C], isPro: true),
        .init(id: "ocean", name: "Ocean", colors: [0x4AC0D6, 0x2E6FA8], isPro: true),
        .init(id: "forest", name: "Forest", colors: [0x6FB97E, 0x2E6F58], isPro: true),
        .init(id: "midnight", name: "Midnight", colors: [0x2A2D5A, 0x121327], isPro: true),
        .init(id: "candy", name: "Candy", colors: [0xFF8FB1, 0xFFC36B], isPro: true),
        .init(id: "lavender", name: "Lavender", colors: [0xD7C8F5, 0xF7D9E3], isPro: true),
        .init(id: "gold", name: "Gold", colors: [0xF3C969, 0xCB8A12], isPro: true),
        .init(id: "noir", name: "Noir", colors: [0x2B2B30, 0x000000], isPro: true)
    ]
    static let free: [BackgroundStyle] = all.filter { !$0.isPro }
    static func byID(_ id: String) -> BackgroundStyle { all.first { $0.id == id } ?? all[0] }
}

enum TextWeight: String, CaseIterable, Identifiable, Codable {
    case regular, bold, heavy, serif
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    func font(size: CGFloat) -> Font {
        switch self {
        case .regular: return .system(size: size, weight: .medium, design: .rounded)
        case .bold: return .system(size: size, weight: .bold, design: .rounded)
        case .heavy: return .system(size: size, weight: .heavy, design: .rounded)
        case .serif: return .system(size: size, weight: .semibold, design: .serif)
        }
    }
}

struct TextOverlay: Identifiable {
    let id = UUID()
    var text: String
    var x: CGFloat            // normalized center 0…1
    var y: CGFloat
    var fontScale: CGFloat    // fraction of canvas height
    var colorHex: UInt
    var weight: TextWeight
    var hasShadow: Bool

    var color: Color { Color(hex: colorHex) }

    static let palette: [UInt] = [0xFFFFFF, 0x141414, 0xDB3573, 0xF3C969, 0x2E6FA8, 0x46C384, 0x8A5CF0]
}
