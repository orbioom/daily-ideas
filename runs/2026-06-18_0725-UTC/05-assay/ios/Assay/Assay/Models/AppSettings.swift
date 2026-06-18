import SwiftUI

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system = "System", light = "Light", dark = "Dark"
    var id: String { rawValue }
    var colorScheme: ColorScheme? {
        self == .system ? nil : (self == .light ? .light : .dark)
    }
}

/// Which display unit to use for markers that support an alternate unit.
enum GlucoseUnit: String, CaseIterable, Identifiable {
    case mgdl = "mg/dL", mmoll = "mmol/L"
    var id: String { rawValue }
}

enum CholesterolUnit: String, CaseIterable, Identifiable {
    case mgdl = "mg/dL", mmoll = "mmol/L"
    var id: String { rawValue }
}

/// App-wide preferences. Persisted via @AppStorage so they survive relaunch.
@MainActor
final class AppSettings: ObservableObject {
    @AppStorage("hapticsEnabled") var hapticsEnabled = true
    @AppStorage("appearance") var appearanceRaw = AppearanceMode.system.rawValue
    @AppStorage("biologicalSex") var biologicalSexRaw = BiologicalSex.unspecified.rawValue
    @AppStorage("glucoseUnit") var glucoseUnitRaw = GlucoseUnit.mgdl.rawValue
    @AppStorage("cholesterolUnit") var cholesterolUnitRaw = CholesterolUnit.mgdl.rawValue
    @AppStorage("showOptimal") var showOptimalRanges = true

    var appearance: AppearanceMode {
        get { AppearanceMode(rawValue: appearanceRaw) ?? .system }
        set { appearanceRaw = newValue.rawValue }
    }

    var biologicalSex: BiologicalSex {
        get { BiologicalSex(rawValue: biologicalSexRaw) ?? .unspecified }
        set { biologicalSexRaw = newValue.rawValue }
    }

    var glucoseUnit: GlucoseUnit {
        get { GlucoseUnit(rawValue: glucoseUnitRaw) ?? .mgdl }
        set { glucoseUnitRaw = newValue.rawValue }
    }

    var cholesterolUnit: CholesterolUnit {
        get { CholesterolUnit(rawValue: cholesterolUnitRaw) ?? .mgdl }
        set { cholesterolUnitRaw = newValue.rawValue }
    }

    /// Preferred display unit for a marker given the user's unit prefs.
    /// Returns nil to mean "use the marker's canonical unit".
    func preferredAltUnit(for marker: Biomarker) -> AltUnit? {
        guard let alt = marker.altUnit else { return nil }
        switch marker.category {
        case .metabolic where marker.id == "glucose":
            return glucoseUnit == .mmoll ? alt : nil
        case .lipids:
            return cholesterolUnit == .mmoll ? alt : nil
        default:
            return nil // Vitamin D etc. stay canonical unless toggled on detail screen
        }
    }
}
