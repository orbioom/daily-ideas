import SwiftUI

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system = "System", light = "Light", dark = "Dark"
    var id: String { rawValue }
    var colorScheme: ColorScheme? {
        self == .system ? nil : (self == .light ? .light : .dark)
    }
    var iconName: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
}

/// The on-screen guide style for tracing.
enum GuideStyle: String, CaseIterable, Identifiable {
    case dots = "Dots", arrows = "Arrows", road = "Road"
    var id: String { rawValue }
    var iconName: String {
        switch self {
        case .dots: return "circle.dotted"
        case .arrows: return "arrow.up.forward"
        case .road: return "road.lanes"
        }
    }
}

/// Selectable ink colors for the child's drawn stroke.
enum InkColor: String, CaseIterable, Identifiable {
    case coral = "Coral", blueberry = "Blueberry", grape = "Grape", leaf = "Leaf", bubblegum = "Bubblegum"
    var id: String { rawValue }
    var color: Color {
        switch self {
        case .coral: return Theme.accent
        case .blueberry: return Color(hex: 0x4C8AFF)
        case .grape: return Color(hex: 0x9B5CE0)
        case .leaf: return Color(hex: 0x4CC26A)
        case .bubblegum: return Color(hex: 0xFF5CA8)
        }
    }
}

@MainActor final class AppSettings: ObservableObject {
    @AppStorage("hapticsEnabled") var hapticsEnabled = true
    @AppStorage("soundEnabled") var soundEnabled = true
    @AppStorage("leftHanded") var leftHanded = false
    @AppStorage("noFailMode") var noFailMode = false
    @AppStorage("guideStyleRaw") var guideStyleRaw = GuideStyle.dots.rawValue
    @AppStorage("inkColorRaw") var inkColorRaw = InkColor.coral.rawValue
    @AppStorage("appearance") var appearanceRaw = AppearanceMode.system.rawValue
    @AppStorage("activeProfileID") var activeProfileIDString = ""

    var appearance: AppearanceMode {
        get { AppearanceMode(rawValue: appearanceRaw) ?? .system }
        set { appearanceRaw = newValue.rawValue }
    }

    var guideStyle: GuideStyle {
        get { GuideStyle(rawValue: guideStyleRaw) ?? .dots }
        set { guideStyleRaw = newValue.rawValue }
    }

    var inkColor: InkColor {
        get { InkColor(rawValue: inkColorRaw) ?? .coral }
        set { inkColorRaw = newValue.rawValue }
    }
}
