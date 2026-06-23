import SwiftUI
import SwiftData

/// Settings tab — persisted preferences plus tools and about.
struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var settings: [AppSettings]
    @AppStorage("hasOnboarded") private var hasOnboarded = false

    @State private var showPlateCalc = false
    @State private var showResetConfirm = false

    private var prefs: AppSettings { SettingsAccess.current(settings, context: context) }

    private let restOptions = [60, 90, 120, 150, 180, 240, 300]

    var body: some View {
        NavigationStack {
            Form {
                unitsSection
                timerSection
                loggingSection
                toolsSection
                aboutSection
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPlateCalc) {
                PlateCalculatorView(initialWeightKg: 0, prefs: prefs)
            }
            .alert("Replay onboarding?", isPresented: $showResetConfirm) {
                Button("Replay", role: .destructive) { hasOnboarded = false }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You'll see the welcome screens again next launch. Your data stays put.")
            }
        }
    }

    private var unitsSection: some View {
        Section("Units") {
            Picker("Weight unit", selection: Binding(
                get: { prefs.unit },
                set: { prefs.unit = $0; save() }
            )) {
                ForEach(WeightUnit.allCases) { Text($0.display.uppercased()).tag($0) }
            }
            HStack {
                Text("Barbell weight")
                Spacer()
                Text(Units.weightString(kg: prefs.barWeightKg, unit: prefs.unit))
                    .foregroundStyle(Theme.textSecondary)
            }
            Stepper("Adjust bar weight",
                    value: Binding(
                        get: { prefs.barWeightKg },
                        set: { prefs.barWeightKg = max(0, $0); save() }
                    ),
                    in: 0...40, step: prefs.unit == .kg ? 2.5 : Units.kgPerLb * 5)
                .labelsHidden()
                .accessibilityLabel("Bar weight stepper")
        }
    }

    private var timerSection: some View {
        Section("Rest timer") {
            Toggle("Auto-start after each set", isOn: Binding(
                get: { prefs.autoStartRestTimer },
                set: { prefs.autoStartRestTimer = $0; save() }
            ))
            Picker("Default rest", selection: Binding(
                get: { prefs.defaultRestSeconds },
                set: { prefs.defaultRestSeconds = $0; save() }
            )) {
                ForEach(restOptions, id: \.self) { sec in
                    Text(Format.clock(Double(sec))).tag(sec)
                }
            }
        }
    }

    private var loggingSection: some View {
        Section("Logging") {
            Toggle("Track RPE", isOn: Binding(
                get: { prefs.trackRPE },
                set: { prefs.trackRPE = $0; save() }
            ))
            Toggle("Haptic feedback", isOn: Binding(
                get: { prefs.hapticsEnabled },
                set: { prefs.hapticsEnabled = $0; save() }
            ))
        }
    }

    private var toolsSection: some View {
        Section("Tools") {
            Button {
                showPlateCalc = true
            } label: {
                Label("Plate Calculator", systemImage: "circle.hexagongrid.fill")
            }
            Button {
                showResetConfirm = true
            } label: {
                Label("Replay Onboarding", systemImage: "sparkles")
            }
        }
    }

    private var aboutSection: some View {
        Section("About") {
            LabeledContent("Version", value: "1.0")
            LabeledContent("e1RM formula", value: "Epley")
            Text("Tempo logs strength training fast: set × rep × weight, automatic PR detection, a calm rest timer, and a barbell plate calculator — all on-device.")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
    }

    private func save() {
        try? context.save()
        Haptics.selection(enabled: prefs.hapticsEnabled)
    }
}

#Preview {
    SettingsView().modelContainer(PersistenceController.preview)
}
