import SwiftUI

struct SettingsView: View {
    @AppStorage("nocturne.onboarded")      private var onboarded      = true
    @AppStorage("nocturne.haptics")        private var hapticsEnabled = true
    @AppStorage("nocturne.clock24")        private var clock24        = false
    @AppStorage("nocturne.weekStart")      private var weekStart      = 0   // 0=Sunday, 1=Monday
    @AppStorage("nocturne.defaultQuality") private var defaultQuality = 3
    @AppStorage("nocturne.appearance")     private var appearance     = "system"

    @State private var showResetConfirm = false
    @State private var showAbout        = false

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground

                List {
                    // Display section
                    Section {
                        // Time format
                        Toggle(isOn: $clock24) {
                            settingsLabel(
                                icon: "clock",
                                iconColor: Brand.info,
                                title: "24-Hour Clock",
                                subtitle: clock24 ? "22:30 style" : "10:30 PM style"
                            )
                        }
                        .tint(Brand.magic)
                        .onChange(of: clock24) { _, _ in Haptics.selection() }
                        .accessibilityLabel("24-hour clock")
                        .accessibilityValue(clock24 ? "On" : "Off")

                        // Week start
                        Picker(selection: $weekStart) {
                            Text("Sunday").tag(0)
                            Text("Monday").tag(1)
                        } label: {
                            settingsLabel(
                                icon: "calendar",
                                iconColor: Brand.magic,
                                title: "Week Starts On",
                                subtitle: weekStart == 0 ? "Sunday" : "Monday"
                            )
                        }
                        .pickerStyle(.menu)
                        .tint(Brand.text2)
                        .onChange(of: weekStart) { _, _ in Haptics.selection() }
                        .accessibilityLabel("Week starts on: \(weekStart == 0 ? "Sunday" : "Monday")")

                        // Appearance
                        Picker(selection: $appearance) {
                            Text("System").tag("system")
                            Text("Light").tag("light")
                            Text("Dark").tag("dark")
                        } label: {
                            settingsLabel(
                                icon: "circle.lefthalf.filled",
                                iconColor: Brand.text3,
                                title: "Appearance",
                                subtitle: appearance.capitalized
                            )
                        }
                        .pickerStyle(.menu)
                        .tint(Brand.text2)
                        .onChange(of: appearance) { _, _ in Haptics.selection() }
                        .accessibilityLabel("Appearance: \(appearance)")
                    } header: {
                        sectionHeader("Display")
                    }
                    .listRowBackground(glassRowBackground)

                    // Logging defaults section
                    Section {
                        // Default quality
                        Picker(selection: $defaultQuality) {
                            ForEach(1...5, id: \.self) { q in
                                Text("\(q) — \(Format.qualityLabel(q))").tag(q)
                            }
                        } label: {
                            settingsLabel(
                                icon: "star.fill",
                                iconColor: Brand.warn,
                                title: "Default Quality",
                                subtitle: Format.qualityLabel(defaultQuality)
                            )
                        }
                        .pickerStyle(.menu)
                        .tint(Brand.text2)
                        .onChange(of: defaultQuality) { _, _ in Haptics.selection() }
                        .accessibilityLabel("Default quality: \(Format.qualityLabel(defaultQuality))")
                    } header: {
                        sectionHeader("Logging")
                    }
                    .listRowBackground(glassRowBackground)

                    // Haptics & accessibility
                    Section {
                        Toggle(isOn: $hapticsEnabled) {
                            settingsLabel(
                                icon: "hand.tap.fill",
                                iconColor: Brand.live,
                                title: "Haptics",
                                subtitle: hapticsEnabled ? "Enabled" : "Disabled"
                            )
                        }
                        .tint(Brand.magic)
                        .onChange(of: hapticsEnabled) { _, newValue in
                            Haptics.enabled = newValue
                        }
                        .accessibilityLabel("Haptics")
                        .accessibilityValue(hapticsEnabled ? "On" : "Off")
                    } header: {
                        sectionHeader("Accessibility")
                    }
                    .listRowBackground(glassRowBackground)

                    // Reset & About
                    Section {
                        Button {
                            Haptics.warning()
                            showResetConfirm = true
                        } label: {
                            settingsLabel(
                                icon: "arrow.counterclockwise",
                                iconColor: Brand.warn,
                                title: "Reset Onboarding",
                                subtitle: "Show the intro screens again"
                            )
                        }
                        .foregroundStyle(Brand.text)
                        .accessibilityHint("Double tap to reset onboarding and see intro screens")

                        Button {
                            showAbout = true
                        } label: {
                            settingsLabel(
                                icon: "info.circle",
                                iconColor: Brand.info,
                                title: "About Nocturne",
                                subtitle: "Version 1.0 · Orbioom"
                            )
                        }
                        .foregroundStyle(Brand.text)
                        .accessibilityHint("Double tap to view app information")
                    } header: {
                        sectionHeader("App")
                    }
                    .listRowBackground(glassRowBackground)
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .confirmationDialog(
                "Reset Onboarding?",
                isPresented: $showResetConfirm,
                titleVisibility: .visible
            ) {
                Button("Reset", role: .destructive) {
                    onboarded = false
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("The intro screens will appear next time you open the app.")
            }
            .sheet(isPresented: $showAbout) {
                AboutView()
            }
        }
    }

    // MARK: - Row helpers

    private func settingsLabel(icon: String, iconColor: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(iconColor.opacity(0.18))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(iconColor)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(Brand.text)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Brand.text3)
            }
        }
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text.uppercased())
            .font(Brand.mono(11, weight: .medium))
            .foregroundStyle(Brand.text3)
            .tracking(1.2)
            .textCase(nil)
    }

    private var glassRowBackground: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(.ultraThinMaterial)
    }
}

// MARK: - About Sheet

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground

                ScrollView {
                    VStack(spacing: 24) {
                        // App icon stand-in
                        ZStack {
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(Brand.inkGradient)
                                .frame(width: 90, height: 90)
                            Image(systemName: "moon.stars.fill")
                                .font(.system(size: 38, weight: .light))
                                .foregroundStyle(.white)
                        }
                        .accessibilityHidden(true)
                        .padding(.top, 24)

                        VStack(spacing: 6) {
                            Text("Nocturne")
                                .font(.largeTitle.weight(.bold))
                                .foregroundStyle(Brand.text)
                            Text("Version 1.0 · Orbioom Studio")
                                .font(Brand.mono(13))
                                .foregroundStyle(Brand.text3)
                        }

                        GlassCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Eyebrow(text: "About")
                                Text("Nocturne is a private, on-device sleep tracker. No account, no subscription, no wearable required.")
                                    .font(.body)
                                    .foregroundStyle(Brand.text2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(.horizontal, 24)

                        GlassCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Eyebrow(text: "Privacy")
                                Text("All your data stays on your device. Nothing is sent to any server. Ever.")
                                    .font(.body)
                                    .foregroundStyle(Brand.text2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(.horizontal, 24)

                        GlassCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Eyebrow(text: "Tech")
                                Text("Built with SwiftUI and SwiftData for iOS 17. Sleep analytics run entirely on-device in pure Swift.")
                                    .font(.body)
                                    .foregroundStyle(Brand.text2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(Brand.text2)
                }
            }
        }
    }
}
