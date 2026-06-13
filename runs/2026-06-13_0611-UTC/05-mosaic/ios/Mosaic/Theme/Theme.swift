import SwiftUI
import UIKit

extension Color {
    init(hex: UInt) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255.0,
                  green: Double((hex >> 8) & 0xFF) / 255.0,
                  blue: Double(hex & 0xFF) / 255.0, opacity: 1.0)
    }
    static func dyn(_ light: UInt, _ dark: UInt) -> Color {
        Color(UIColor { tc in
            let h = tc.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat((h >> 16) & 0xFF) / 255.0,
                           green: CGFloat((h >> 8) & 0xFF) / 255.0,
                           blue: CGFloat(h & 0xFF) / 255.0, alpha: 1.0)
        })
    }
}

struct Mood: Identifiable {
    let index: Int
    let name: String
    let light: UInt
    let dark: UInt
    var id: Int { index }
    var color: Color { .dyn(light, dark) }
}

/// Mosaic — warm, playful, a sunset palette and a year of colored tiles.
enum Theme {
    static let bg        = Color.dyn(0xFCF6F1, 0x15110F)
    static let surface   = Color.dyn(0xFFFFFF, 0x211C19)
    static let surfaceAlt = Color.dyn(0xF1E7DE, 0x2B2521)
    static let ink       = Color.dyn(0x241B16, 0xF4EDE6)
    static let inkSoft   = Color.dyn(0x6B5C52, 0xB5A99E)
    static let inkFaint  = Color.dyn(0x9C8B7E, 0x7A6E64)
    static let accent    = Color.dyn(0xD8542F, 0xEE7350)   // terracotta
    static let hairline  = Color.dyn(0xE7DACE, 0x322A24)

    static let emptyTile = Color.dyn(0xEADFD4, 0x2A231E)

    static let moods: [Mood] = [
        Mood(index: 1, name: "Rough",  light: 0xC75146, dark: 0xD06457),
        Mood(index: 2, name: "Meh",    light: 0xE08A4B, dark: 0xE49A5F),
        Mood(index: 3, name: "Okay",   light: 0xE6C25C, dark: 0xE9CB72),
        Mood(index: 4, name: "Good",   light: 0x8FB96B, dark: 0x9DC47C),
        Mood(index: 5, name: "Great",  light: 0x4DA38B, dark: 0x5FB49C)
    ]

    static func mood(_ index: Int) -> Mood? { moods.first { $0.index == index } }
    static func moodColor(_ index: Int) -> Color { mood(index)?.color ?? emptyTile }

    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}
