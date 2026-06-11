import SwiftUI

struct DripSettingsView: View {
    @AppStorage("hapticsEnabled") private var haptics = true
    @AppStorage("showStandardDrinks") private var showSD = true
    @AppStorage("unitSystem") private var unitSystem = "ml"

    var body: some View {
        NavigationStack {
            Form {
                Section("Display") {
                    Toggle("Show standard drinks", isOn: $showSD)
                        .tint(DripTheme.accent)
                        .accessibilityLabel("Show standard drink count on entries")
                    Picker("Volume units", selection: $unitSystem) {
                        Text("mL").tag("ml")
                        Text("fl oz").tag("floz")
                    }
                    .accessibilityLabel("Volume unit preference")
                }
                Section("Feedback") {
                    Toggle("Haptics", isOn: $haptics)
                        .tint(DripTheme.accent)
                        .accessibilityLabel("Haptic feedback")
                }
                Section("About") {
                    HStack { Text("Standard drink"); Spacer(); Text("14g pure alcohol (US)").font(.caption).foregroundStyle(DripTheme.subtle) }
                    HStack { Text("Version"); Spacer(); Text("1.0").foregroundStyle(DripTheme.subtle) }
                    HStack { Text("Data"); Spacer(); Text("On-device only").font(.caption).foregroundStyle(DripTheme.subtle) }
                }
            }
            .scrollContentBackground(.hidden)
            .background(DripTheme.bg)
            .navigationTitle("Settings")
        }
    }
}
