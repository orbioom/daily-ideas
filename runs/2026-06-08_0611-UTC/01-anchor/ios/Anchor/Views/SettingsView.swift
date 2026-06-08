import SwiftUI

struct SettingsView: View {
    @AppStorage("anchor.haptics")      private var haptics = true
    @AppStorage("anchor.weekStart")    private var weekStart = "sunday"
    @AppStorage("anchor.appearance")   private var appearance = "system"
    @AppStorage("anchor.showArchived") private var showArchived = false
    @AppStorage("anchor.onboarded")    private var onboarded = true

    @State private var showResetConfirm = false

    private let appVersion: String = {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }()

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground

                Form {
                    // Preferences
                    Section {
                        // Week start
                        Picker("Week starts on", selection: $weekStart) {
                            Text("Sunday").tag("sunday")
                            Text("Monday").tag("monday")
                        }
                        .foregroundStyle(Brand.text)
                        .accessibilityLabel("Week starts on")
                        .accessibilityValue(weekStart.capitalized)

                        // Appearance
                        Picker("Appearance", selection: $appearance) {
                            Text("System").tag("system")
                            Text("Light").tag("light")
                            Text("Dark").tag("dark")
                        }
                        .foregroundStyle(Brand.text)
                        .accessibilityLabel("Appearance")
                        .accessibilityValue(appearance.capitalized)

                        // Show archived
                        Toggle("Show Archived Habits", isOn: $showArchived)
                            .tint(Brand.live)
                            .foregroundStyle(Brand.text)
                            .accessibilityLabel("Show archived habits")
                            .accessibilityValue(showArchived ? "on" : "off")

                        // Haptics
                        Toggle("Haptic Feedback", isOn: $haptics)
                            .tint(Brand.live)
                            .foregroundStyle(Brand.text)
                            .accessibilityLabel("Haptic feedback")
                            .accessibilityValue(haptics ? "on" : "off")
                            .onChange(of: haptics) { _, v in Haptics.enabled = v }
                    } header: {
                        Eyebrow(text: "Preferences")
                    }

                    // Account / Reset
                    Section {
                        Button(role: .destructive) {
                            showResetConfirm = true
                            Haptics.warning()
                        } label: {
                            HStack {
                                Image(systemName: "arrow.counterclockwise.circle")
                                    .accessibilityHidden(true)
                                Text("Replay Onboarding")
                            }
                            .foregroundStyle(Brand.danger)
                        }
                        .accessibilityLabel("Replay onboarding")
                        .accessibilityHint("Shows the introduction screens again")
                    } header: {
                        Eyebrow(text: "Reset")
                    } footer: {
                        Text("This only shows onboarding again — your habits and data are kept.")
                            .font(.caption)
                            .foregroundStyle(Brand.text3)
                    }

                    // About
                    Section {
                        LabeledContent("App", value: "Anchor")
                        LabeledContent("Version", value: appVersion)
                        LabeledContent("Studio", value: "Orbioom")
                        LabeledContent("Platform", value: "iOS 17+, on-device")
                    } header: {
                        Eyebrow(text: "About")
                    } footer: {
                        Text("Anchor keeps your habits and all data 100% on your device. No account, no cloud, no ads — ever.")
                            .font(.caption)
                            .foregroundStyle(Brand.text3)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .confirmationDialog(
                "Replay Onboarding?",
                isPresented: $showResetConfirm,
                titleVisibility: .visible
            ) {
                Button("Replay Onboarding", role: .destructive) {
                    onboarded = false
                    Haptics.success()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your habits and data will not be affected.")
            }
        }
    }
}
