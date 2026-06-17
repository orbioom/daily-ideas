import SwiftUI

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system = "System", light = "Light", dark = "Dark"
    var id: String { rawValue }
    var colorScheme: ColorScheme? { self == .system ? nil : (self == .light ? .light : .dark) }
}

/// App-wide persisted preferences. Uses the ObservableObject pattern (paired with @StateObject in MuralApp).
@MainActor
final class AppSettings: ObservableObject {
    @AppStorage("hapticsEnabled") var hapticsEnabled = true
    @AppStorage("appearance") var appearanceRaw = AppearanceMode.system.rawValue
    @AppStorage("grainOnByDefault") var grainOnByDefault = true
    @AppStorage("defaultAspectRaw") var defaultAspectRaw = AspectRatioOption.phone.rawValue

    var appearance: AppearanceMode {
        get { AppearanceMode(rawValue: appearanceRaw) ?? .system }
        set { appearanceRaw = newValue.rawValue }
    }

    var defaultAspect: AspectRatioOption {
        get { AspectRatioOption(rawValue: defaultAspectRaw) ?? .phone }
        set { defaultAspectRaw = newValue.rawValue }
    }
}
