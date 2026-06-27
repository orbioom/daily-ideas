import SwiftUI
import SwiftData

struct StrokeSettingsView: View {
    @Query private var settingsArr: [StrokeSettings]
    @Environment(\.modelContext) private var context

    private var s: StrokeSettings { settingsArr.first ?? StrokeSettings.fetch(context: context) }

    var body: some View {
        NavigationStack {
            Form {
                Section("Display") {
                    Toggle("Show Watts", isOn: Binding(
                        get: { s.displayWatts }, set: { s.displayWatts = $0; save() }
                    ))
                    Text("Watts are computed from 500m split: P = 2.80/(split/500)³")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Section("Goals") {
                    Picker("Weekly Distance Goal", selection: Binding(
                        get: { s.weeklyDistanceGoalM }, set: { s.weeklyDistanceGoalM = $0; save() }
                    )) {
                        Text("5 km").tag(5000)
                        Text("10 km").tag(10000)
                        Text("20 km").tag(20000)
                        Text("30 km").tag(30000)
                        Text("50 km").tag(50000)
                        Text("75 km").tag(75000)
                    }
                }
                Section("Profile") {
                    HStack {
                        Text("Body Weight")
                        Spacer()
                        TextField("75", value: Binding(
                            get: { s.weightKg }, set: { s.weightKg = $0; save() }
                        ), format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                        Text("kg").foregroundStyle(.secondary)
                    }
                }
                Section("Accessibility") {
                    Toggle("Enable Haptics", isOn: Binding(
                        get: { s.enableHaptics }, set: { s.enableHaptics = $0; save() }
                    ))
                }
                Section("Training Zones (watts)") {
                    zoneRow("UT2", range: "< 100 W", color: .blue)
                    zoneRow("UT1", range: "100–130 W", color: .cyan)
                    zoneRow("AT", range: "130–160 W", color: .green)
                    zoneRow("TR", range: "160–200 W", color: .yellow)
                    zoneRow("AN", range: "> 200 W", color: .red)
                }
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0").foregroundStyle(.secondary)
                    }
                    Text("Stroke is private and on-device. No account required.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
        }
    }

    private func save() { try? context.save() }

    private func zoneRow(_ name: String, range: String, color: Color) -> some View {
        HStack {
            Circle().fill(color).frame(width: 10, height: 10)
                .accessibilityHidden(true)
            Text(name).font(.subheadline.bold())
            Spacer()
            Text(range).font(.caption).foregroundStyle(.secondary)
        }
    }
}
