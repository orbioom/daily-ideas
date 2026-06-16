import SwiftUI

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system = "System", light = "Light", dark = "Dark"
    var id: String { rawValue }
    var colorScheme: ColorScheme? { self == .system ? nil : (self == .light ? .light : .dark) }
}

/// Which ear the screening starts with.
enum EarOrder: String, CaseIterable, Identifiable {
    case rightFirst = "Right first", leftFirst = "Left first"
    var id: String { rawValue }
    var firstEar: Ear { self == .rightFirst ? .right : .left }
    var secondEar: Ear { self == .rightFirst ? .left : .right }
}

@MainActor final class AppSettings: ObservableObject {
    @AppStorage("hapticsEnabled") var hapticsEnabled = true
    @AppStorage("appearance") var appearanceRaw = AppearanceMode.system.rawValue

    /// Order of ears in the screening.
    @AppStorage("earOrder") var earOrderRaw = EarOrder.rightFirst.rawValue
    /// Tone presentation duration in seconds (0.8 – 2.5).
    @AppStorage("toneDuration") var toneDuration: Double = 1.5
    /// Highest relative test level in dB-HL-ish units (the "loudest" tone the screener will reach).
    @AppStorage("maxTestLevel") var maxTestLevel: Double = 80
    /// How long to wait for a response before counting "no response" (seconds, 2.0 – 5.0).
    @AppStorage("responseTimeout") var responseTimeout: Double = 3.0

    var appearance: AppearanceMode {
        get { AppearanceMode(rawValue: appearanceRaw) ?? .system }
        set { appearanceRaw = newValue.rawValue }
    }

    var earOrder: EarOrder {
        get { EarOrder(rawValue: earOrderRaw) ?? .rightFirst }
        set { earOrderRaw = newValue.rawValue }
    }
}
