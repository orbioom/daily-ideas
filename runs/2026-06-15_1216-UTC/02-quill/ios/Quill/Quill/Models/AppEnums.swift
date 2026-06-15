import SwiftUI

// MARK: - Appearance

/// User-selectable color scheme preference.
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

// MARK: - Drawing input policy

/// Maps to `PKCanvasView.drawingPolicy`.
enum InputPolicy: String, CaseIterable, Identifiable {
    case anyInput
    case pencilOnly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .anyInput: return "Finger & Pencil"
        case .pencilOnly: return "Pencil Only"
        }
    }
}

// MARK: - Library sorting

enum NotebookSort: String, CaseIterable, Identifiable {
    case recent
    case title
    case pageCount

    var id: String { rawValue }

    var title: String {
        switch self {
        case .recent: return "Recent"
        case .title: return "Title"
        case .pageCount: return "Page Count"
        }
    }

    var systemImage: String {
        switch self {
        case .recent: return "clock"
        case .title: return "textformat"
        case .pageCount: return "doc.on.doc"
        }
    }
}
