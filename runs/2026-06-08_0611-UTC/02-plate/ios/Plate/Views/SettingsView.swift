import SwiftUI

struct SettingsView: View {
    @AppStorage("plate.haptics")    private var hapticsEnabled = true
    @AppStorage("plate.units")      private var imperialUnits  = false
    @AppStorage("plate.showMacros") private var showMacros     = true
    @AppStorage("plate.appearance") private var appearance     = "system"
    @AppStorage("plate.onboarded")  private var onboarded      = true

    @State private var showResetConfirm = false
    @State private var showAbout = false

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                List {
                    // Preferences
                    Section {
                        Toggle("Haptic Feedback", isOn: $hapticsEnabled)
                            .tint(Brand.magic)
                            .foregroundStyle(Brand.text)
                            .accessibilityLabel("Haptic feedback")
                            .accessibilityHint("Enables or disables vibration feedback throughout the app")

                        Toggle("Show Macros in Diary", isOn: $showMacros)
                            .tint(Brand.magic)
                            .foregroundStyle(Brand.text)
                            .accessibilityLabel("Show macros in diary")
                            .accessibilityHint("Toggles display of protein, carbs and fat on diary entries")

                        Toggle("Imperial Units", isOn: $imperialUnits)
                            .tint(Brand.magic)
                            .foregroundStyle(Brand.text)
                            .accessibilityLabel("Imperial units")
                            .accessibilityHint("When on, height shows in feet/inches and weight in lbs")
                    } header: {
                        Text("Preferences")
                            .foregroundStyle(Brand.text3)
                    }
                    .listRowBackground(Color.clear)

                    // Appearance
                    Section {
                        Picker("Appearance", selection: $appearance) {
                            Text("System").tag("system")
                            Text("Light").tag("light")
                            Text("Dark").tag("dark")
                        }
                        .pickerStyle(.segmented)
                        .accessibilityLabel("App appearance: \(appearance)")
                    } header: {
                        Text("Appearance")
                            .foregroundStyle(Brand.text3)
                    } footer: {
                        Text("System follows your device's appearance setting.")
                            .foregroundStyle(Brand.text3)
                    }
                    .listRowBackground(Color.clear)

                    // Account / Reset
                    Section {
                        Button {
                            showResetConfirm = true
                        } label: {
                            Label("Show Onboarding Again", systemImage: "arrow.counterclockwise")
                                .foregroundStyle(Brand.warn)
                        }
                        .accessibilityLabel("Show onboarding again")
                        .accessibilityHint("Resets the onboarding flag so the intro screens appear on next launch")
                    } header: {
                        Text("Reset")
                            .foregroundStyle(Brand.text3)
                    }
                    .listRowBackground(Color.clear)

                    // About
                    Section {
                        Button {
                            showAbout = true
                        } label: {
                            Label("About Plate", systemImage: "info.circle")
                                .foregroundStyle(Brand.info)
                        }
                        .accessibilityLabel("About Plate")
                    } header: {
                        Text("About")
                            .foregroundStyle(Brand.text3)
                    }
                    .listRowBackground(Color.clear)
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .confirmationDialog(
                "Show onboarding?",
                isPresented: $showResetConfirm,
                titleVisibility: .visible
            ) {
                Button("Show Onboarding", role: .destructive) {
                    onboarded = false
                    Haptics.warning()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("The intro screens will appear the next time you open the app.")
            }
            .sheet(isPresented: $showAbout) {
                AboutView()
            }
        }
    }
}

// MARK: - About sheet

private struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(spacing: 8) {
                            Image(systemName: "fork.knife.circle.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(Brand.magic)
                                .accessibilityHidden(true)
                            Text("Plate")
                                .font(.largeTitle.weight(.bold))
                                .foregroundStyle(Brand.text)
                            Text("Calories without the clutter.")
                                .font(.subheadline)
                                .foregroundStyle(Brand.text2)
                            Text("Version 1.0")
                                .font(.caption)
                                .foregroundStyle(Brand.text3)
                        }
                        .padding(.top, 20)

                        GlassCard {
                            VStack(alignment: .leading, spacing: 10) {
                                aboutRow(icon: "lock.shield.fill",    text: "Fully on-device — no account, no cloud sync, no data sharing.")
                                aboutRow(icon: "creditcard.trianglebadge.exclamationmark", text: "Zero paywalls on core features. No ads. Ever.")
                                aboutRow(icon: "bolt.fill",           text: "Mifflin-St Jeor TDEE engine with macro targets computed from your stats.")
                                aboutRow(icon: "chart.bar.fill",      text: "Swift Charts for beautiful, interactive trends.")
                                aboutRow(icon: "cylinder.split.1x2.fill", text: "SwiftData persistence — your data stays yours.")
                            }
                        }

                        GlassCard {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Built by Orbioom")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Brand.text)
                                Text("Plate is part of the Orbioom daily-ideas initiative — production-quality apps built fast, built right.")
                                    .font(.caption)
                                    .foregroundStyle(Brand.text2)
                            }
                        }
                    }
                    .padding(16)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Brand.text2)
                }
            }
        }
    }

    private func aboutRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(Brand.magic)
                .frame(width: 20)
                .accessibilityHidden(true)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Brand.text2)
        }
    }
}
