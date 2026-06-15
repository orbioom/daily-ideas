import SwiftUI

/// Reading theme applied inside the Reader (independent of app appearance).
enum ReaderTheme: String, CaseIterable, Identifiable {
    case light
    case sepia
    case dark
    case night

    var id: String { rawValue }

    var title: String {
        switch self {
        case .light: return "Light"
        case .sepia: return "Sepia"
        case .dark:  return "Dark"
        case .night: return "Night"
        }
    }

    var background: Color {
        switch self {
        case .light: return Color(hex: 0xFBF8F2)
        case .sepia: return Color(hex: 0xF3E9D6)
        case .dark:  return Color(hex: 0x1C1813)
        case .night: return Color(hex: 0x0D0B09)
        }
    }

    var ink: Color {
        switch self {
        case .light: return Color(hex: 0x2A2419)
        case .sepia: return Color(hex: 0x40341F)
        case .dark:  return Color(hex: 0xE7DECF)
        case .night: return Color(hex: 0xB9AE9C)
        }
    }

    var inkSoft: Color {
        switch self {
        case .light: return Color(hex: 0x6F6450)
        case .sepia: return Color(hex: 0x7A6843)
        case .dark:  return Color(hex: 0xA59A88)
        case .night: return Color(hex: 0x80755F)
        }
    }

    /// Reader themes that imply a dark status bar / chrome.
    var isDark: Bool { self == .dark || self == .night }
}

/// Reader font family.
enum ReaderFont: String, CaseIterable, Identifiable {
    case serif
    case sans
    case rounded

    var id: String { rawValue }

    var title: String {
        switch self {
        case .serif: return "Serif"
        case .sans: return "Sans"
        case .rounded: return "Rounded"
        }
    }

    var design: Font.Design {
        switch self {
        case .serif: return .serif
        case .sans: return .default
        case .rounded: return .rounded
        }
    }
}

/// App-wide appearance preference.
enum AppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

/// Sort orders for the reading list.
enum ArticleSort: String, CaseIterable, Identifiable {
    case recent
    case longest
    case shortest

    var id: String { rawValue }

    var title: String {
        switch self {
        case .recent: return "Recently saved"
        case .longest: return "Longest read"
        case .shortest: return "Shortest read"
        }
    }
}
