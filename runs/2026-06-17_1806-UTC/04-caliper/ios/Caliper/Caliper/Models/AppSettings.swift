import SwiftUI

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system = "System", light = "Light", dark = "Dark"
    var id: String { rawValue }
    var colorScheme: ColorScheme? {
        self == .system ? nil : (self == .light ? .light : .dark)
    }
}

enum UnitSystem: String, CaseIterable, Identifiable {
    case metric = "Metric", imperial = "Imperial"
    var id: String { rawValue }

    /// Display label for length sites.
    var lengthUnit: String { self == .metric ? "cm" : "in" }
    /// Display label for mass sites.
    var massUnit: String { self == .metric ? "kg" : "lb" }
}

enum BiologicalSex: String, CaseIterable, Identifiable {
    case male = "Male", female = "Female"
    var id: String { rawValue }
}

@MainActor
final class AppSettings: ObservableObject {
    @AppStorage("hapticsEnabled") var hapticsEnabled = true
    @AppStorage("appearance") var appearanceRaw = AppearanceMode.system.rawValue
    @AppStorage("unitSystem") var unitSystemRaw = UnitSystem.metric.rawValue
    @AppStorage("biologicalSex") var biologicalSexRaw = BiologicalSex.male.rawValue
    /// Height stored canonically in centimetres for the Navy formula and BMI/FFMI.
    @AppStorage("heightCm") var heightCm: Double = 175

    var appearance: AppearanceMode {
        get { AppearanceMode(rawValue: appearanceRaw) ?? .system }
        set { appearanceRaw = newValue.rawValue }
    }

    var unitSystem: UnitSystem {
        get { UnitSystem(rawValue: unitSystemRaw) ?? .metric }
        set { unitSystemRaw = newValue.rawValue }
    }

    var biologicalSex: BiologicalSex {
        get { BiologicalSex(rawValue: biologicalSexRaw) ?? .male }
        set { biologicalSexRaw = newValue.rawValue }
    }
}
