import SwiftUI

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system = "System", light = "Light", dark = "Dark"
    var id: String { rawValue }
    var colorScheme: ColorScheme? { self == .system ? nil : (self == .light ? .light : .dark) }
    var symbol: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
}

@MainActor
final class AppSettings: ObservableObject {
    @AppStorage("hapticsEnabled") var hapticsEnabled = true
    @AppStorage("appearance") var appearanceRaw = AppearanceMode.system.rawValue
    /// The template pre-selected when creating a new board.
    @AppStorage("defaultTemplate") var defaultTemplateRaw = BoardTemplate.todoDoingDone.rawValue
    /// When false, completed cards are hidden from columns and agenda.
    @AppStorage("showCompletedCards") var showCompletedCards = true
    /// When true, destructive actions ask for confirmation first.
    @AppStorage("confirmBeforeDelete") var confirmBeforeDelete = true

    var appearance: AppearanceMode {
        get { AppearanceMode(rawValue: appearanceRaw) ?? .system }
        set { appearanceRaw = newValue.rawValue }
    }

    var defaultTemplate: BoardTemplate {
        get { BoardTemplate(rawValue: defaultTemplateRaw) ?? .todoDoingDone }
        set { defaultTemplateRaw = newValue.rawValue }
    }
}
