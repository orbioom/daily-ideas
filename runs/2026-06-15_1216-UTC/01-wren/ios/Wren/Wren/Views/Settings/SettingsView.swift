import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var settings: AppSettings
    @Query private var companions: [Companion]

    @State private var renameText: String = ""
    @State private var showPaywall = false
    @State private var showRename = false

    private var companion: Companion? { companions.first }

    var body: some View {
        Form {
            // MARK: Companion
            Section("Companion") {
                HStack {
                    Text("Name")
                    Spacer()
                    Text(companion?.name ?? "Wren")
                        .foregroundStyle(Theme.inkSoft)
                }
                Button("Rename companion") {
                    renameText = companion?.name ?? ""
                    showRename = true
                }
                if let companion, !companion.ownedCosmetics.isEmpty {
                    Picker("Accessory", selection: Binding(
                        get: { companion.equippedAccessory ?? "" },
                        set: { newValue in
                            companion.equippedAccessory = newValue.isEmpty ? nil : newValue
                            try? modelContext.save()
                        }
                    )) {
                        Text("None").tag("")
                        ForEach(companion.ownedCosmetics, id: \.self) { cos in
                            Text(cos.capitalized).tag(cos)
                        }
                    }
                }
            }

            // MARK: Preferences
            Section("Preferences") {
                Picker("Appearance", selection: Binding(
                    get: { settings.appearance },
                    set: { settings.appearance = $0 }
                )) {
                    ForEach(AppearanceMode.allCases) { Text($0.rawValue).tag($0) }
                }
                Toggle("Haptics", isOn: $settings.hapticsEnabled)
                Toggle("Gentle reminders", isOn: $settings.remindersEnabled)
                Stepper(value: $settings.dailyGoalTarget, in: 1...10) {
                    Text("Daily goal target: \(settings.dailyGoalTarget)")
                }
                .accessibilityValue("\(settings.dailyGoalTarget) per day")
            }

            // MARK: Pro
            Section("Wren Pro") {
                if settings.isPro {
                    Label("Pro unlocked — thank you", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(Theme.good)
                    Button("Restore / manage") { showPaywall = true }
                } else {
                    Button {
                        showPaywall = true
                    } label: {
                        HStack {
                            Label("Unlock Wren Pro", systemImage: "crown.fill")
                            Spacer()
                            Text(Pro.priceLabel).foregroundStyle(Theme.inkSoft)
                        }
                    }
                }
            }

            // MARK: About
            Section {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0").foregroundStyle(Theme.inkSoft)
                }
            } footer: {
                Text("Wren keeps everything on your device. No account, no ads, no subscription — just one calm, one-time unlock.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.bg)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) { PaywallView(reason: .general) }
        .alert("Rename companion", isPresented: $showRename) {
            TextField("Name", text: $renameText)
            Button("Save") { saveRename() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("What would you like to call your Wren?")
        }
    }

    private func saveRename() {
        let trimmed = renameText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, let companion else { return }
        companion.name = trimmed
        try? modelContext.save()
        settings.haptic(.soft)
    }
}
