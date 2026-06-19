import SwiftUI

struct SettingsView: View {
    @AppStorage(TrekSettings.distanceUnit) private var distanceUnitRaw = DistanceUnit.km.rawValue
    @AppStorage(TrekSettings.elevationUnit) private var elevationUnitRaw = ElevationUnit.meters.rawValue
    @AppStorage(TrekSettings.hapticFeedback) private var hapticEnabled = true
    @AppStorage(TrekSettings.defaultDifficulty) private var defaultDifficultyRaw = TrailDifficulty.moderate.rawValue

    private var distanceUnit: Binding<DistanceUnit> {
        Binding(
            get: { DistanceUnit(rawValue: distanceUnitRaw) ?? .km },
            set: { distanceUnitRaw = $0.rawValue }
        )
    }
    private var elevationUnit: Binding<ElevationUnit> {
        Binding(
            get: { ElevationUnit(rawValue: elevationUnitRaw) ?? .meters },
            set: { elevationUnitRaw = $0.rawValue }
        )
    }
    private var defaultDifficulty: Binding<TrailDifficulty> {
        Binding(
            get: { TrailDifficulty(rawValue: defaultDifficultyRaw) ?? .moderate },
            set: { defaultDifficultyRaw = $0.rawValue }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Units") {
                    Picker("Distance", selection: distanceUnit) {
                        ForEach(DistanceUnit.allCases, id: \.self) {
                            Text($0.rawValue).tag($0)
                        }
                    }
                    Picker("Elevation", selection: elevationUnit) {
                        ForEach(ElevationUnit.allCases, id: \.self) {
                            Text($0.rawValue).tag($0)
                        }
                    }
                }

                Section("Logging Defaults") {
                    Picker("Default Difficulty", selection: defaultDifficulty) {
                        ForEach(TrailDifficulty.allCases, id: \.self) { d in
                            Label(d.rawValue, systemImage: d.icon).tag(d)
                        }
                    }
                }

                Section("Feedback") {
                    Toggle("Haptic Feedback", isOn: $hapticEnabled)
                        .tint(TrekTheme.forestGreen)
                }

                Section("About") {
                    LabeledContent("App", value: "Trek")
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Storage", value: "On-device only")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}
