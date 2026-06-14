import SwiftUI

/// User preferences — UserDefaults-backed (not SwiftData).
final class AppSettings: ObservableObject {
    @AppStorage("hapticsEnabled") var hapticsEnabled: Bool = true
    @AppStorage("soundEnabled") var soundEnabled: Bool = true
    @AppStorage("keepScreenAwake") var keepScreenAwake: Bool = true
    @AppStorage("dailyMinutesGoal") var dailyMinutesGoal: Int = 20
    @AppStorage("defaultAmbient") var defaultAmbient: String = Ambient.none.rawValue

    var defaultAmbientValue: Ambient {
        get { Ambient(rawValue: defaultAmbient) ?? .none }
        set { defaultAmbient = newValue.rawValue }
    }
}
