import SwiftUI
import SwiftData

struct KataSettingsView: View {
    @Query private var settingsList: [KataSettings]
    @Environment(\.modelContext) private var modelContext
    @Query private var results: [WODResult]
    @Query private var prs: [PersonalRecord]

    private var settings: KataSettings {
        if let s = settingsList.first { return s }
        let s = KataSettings(); modelContext.insert(s); return s
    }

    var body: some View {
        ZStack {
            KataTheme.background.ignoresSafeArea()
            List {
                prefsSection
                statsSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .listStyle(.insetGrouped)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(KataTheme.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    var prefsSection: some View {
        Section {
            TextField("Box Name", text: Binding(
                get: { settings.boxName },
                set: { settings.boxName = $0 }
            ))
            .foregroundStyle(KataTheme.textPrimary)

            Picker("Weight Unit", selection: Binding(
                get: { settings.weightUnit },
                set: { settings.weightUnit = $0 }
            )) {
                Text("Pounds (lb)").tag("lb")
                Text("Kilograms (kg)").tag("kg")
            }
            .foregroundStyle(KataTheme.textPrimary)

            Toggle("Haptic Feedback", isOn: Binding(
                get: { settings.hapticsEnabled },
                set: { settings.hapticsEnabled = $0 }
            ))
            .foregroundStyle(KataTheme.textPrimary)
            .tint(KataTheme.accent)
        } header: {
            Text("Preferences").foregroundStyle(KataTheme.textSecondary)
        }
        .listRowBackground(KataTheme.surface)
    }

    var statsSection: some View {
        let rxCount = results.filter { $0.rx }.count
        return Section {
            statRow("WODs Logged", "\(results.count)")
            statRow("RX WODs", "\(rxCount)")
            statRow("PRs Tracked", "\(prs.count)")
        } header: {
            Text("Your Stats").foregroundStyle(KataTheme.textSecondary)
        }
        .listRowBackground(KataTheme.surface)
    }

    func statRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(KataTheme.textSecondary)
            Spacer()
            Text(value).foregroundStyle(KataTheme.textPrimary)
        }
    }

    var aboutSection: some View {
        Section {
            statRow("Version", "1.0")
            statRow("Built-in WODs", "\(BuiltInWOD.all.count)")
            statRow("Movements Library", "\(commonMovements.count)+")
        } header: {
            Text("About Kata").foregroundStyle(KataTheme.textSecondary)
        }
        .listRowBackground(KataTheme.surface)
    }
}
