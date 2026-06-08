import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage("verdant.haptics") private var hapticsEnabled = true
    @AppStorage("verdant.seasonal") private var seasonalAdjust = true
    @AppStorage("verdant.appearance") private var appearanceRaw = "system"
    @AppStorage("verdant.onboarded") private var onboarded = true
    @AppStorage("verdant.reminderTime") private var reminderTimeInterval: Double = 8.0 * 3600

    @State private var showResetOnboardingConfirm = false
    @State private var showAbout = false

    private let appearanceOptions: [(label: String, value: String)] = [
        ("System", "system"),
        ("Light", "light"),
        ("Dark", "dark")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground

                Form {
                    careSection
                    appearanceSection
                    remindersSection
                    aboutSection
                    resetSection
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showAbout) {
                AboutView()
            }
            .alert("Reset Onboarding?", isPresented: $showResetOnboardingConfirm) {
                Button("Reset", role: .destructive) {
                    onboarded = false
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You'll see the welcome screens again on next launch.")
            }
        }
    }

    private var careSection: some View {
        Section {
            Toggle(isOn: $hapticsEnabled) {
                Label("Haptic Feedback", systemImage: "hand.tap.fill")
                    .foregroundStyle(Brand.text)
            }
            .onChange(of: hapticsEnabled) { _, newValue in
                Haptics.enabled = newValue
            }
            .accessibilityLabel("Haptic feedback toggle")

            Toggle(isOn: $seasonalAdjust) {
                VStack(alignment: .leading, spacing: 2) {
                    Label("Seasonal Adjustment", systemImage: "sun.max.fill")
                        .foregroundStyle(Brand.text)
                    Text("Adjusts watering intervals for summer and winter")
                        .font(.caption)
                        .foregroundStyle(Brand.text3)
                }
            }
            .accessibilityLabel("Seasonal adjustment toggle")
            .accessibilityHint("Shortens watering intervals in summer and lengthens them in winter")
        } header: {
            Text("Care Engine")
        }
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("Color Scheme", selection: $appearanceRaw) {
                ForEach(appearanceOptions, id: \.value) { opt in
                    Text(opt.label).tag(opt.value)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Color scheme picker")
        }
    }

    private var remindersSection: some View {
        Section {
            DatePicker(
                "Reminder Time",
                selection: Binding(
                    get: {
                        let cal = Calendar.current
                        let secs = reminderTimeInterval
                        let hours = Int(secs / 3600) % 24
                        let mins = Int(secs / 60) % 60
                        return cal.date(bySettingHour: hours, minute: mins, second: 0, of: Date()) ?? Date()
                    },
                    set: { newDate in
                        let cal = Calendar.current
                        let h = cal.component(.hour, from: newDate)
                        let m = cal.component(.minute, from: newDate)
                        reminderTimeInterval = Double(h * 3600 + m * 60)
                    }
                ),
                displayedComponents: .hourAndMinute
            )
            .accessibilityLabel("Preferred reminder time")
            .accessibilityHint("Stores your preferred notification time. Enable reminders in iOS Settings.")

            Label {
                Text("Enable in iOS Settings → Notifications → Verdant")
                    .font(.caption)
                    .foregroundStyle(Brand.text3)
            } icon: {
                Image(systemName: "bell.badge")
                    .foregroundStyle(Brand.text3)
            }
        } header: {
            Text("Reminders")
        } footer: {
            Text("Verdant stores your preferred time. To receive notifications, enable them in iOS Settings.")
        }
    }

    private var aboutSection: some View {
        Section("About") {
            Button {
                showAbout = true
                Haptics.tap()
            } label: {
                HStack {
                    Label("About Verdant", systemImage: "leaf.fill")
                        .foregroundStyle(Brand.text)
                    Spacer()
                    Text("v1.0")
                        .font(.caption)
                        .foregroundStyle(Brand.text3)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Brand.text3)
                }
            }
            .accessibilityLabel("About Verdant, version 1.0")
        }
    }

    private var resetSection: some View {
        Section {
            Button {
                showResetOnboardingConfirm = true
                Haptics.tap()
            } label: {
                Label("Reset Onboarding", systemImage: "arrow.counterclockwise")
                    .foregroundStyle(Brand.warn)
            }
            .accessibilityLabel("Reset onboarding screens")
            .accessibilityHint("You will see the welcome introduction again")
        } header: {
            Text("Developer")
        }
    }
}

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground

                ScrollView {
                    VStack(spacing: 28) {
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Brand.live.opacity(0.12))
                                    .frame(width: 88, height: 88)
                                Image(systemName: "leaf.fill")
                                    .font(.system(size: 36, weight: .medium))
                                    .foregroundStyle(Brand.live)
                                    .accessibilityHidden(true)
                            }
                            Text("Verdant")
                                .font(.title.weight(.bold))
                                .foregroundStyle(Brand.text)
                            Text("Plants, kept alive — calmly.")
                                .font(.subheadline)
                                .foregroundStyle(Brand.text2)
                            Text("Version 1.0")
                                .font(.caption)
                                .foregroundStyle(Brand.text3)
                        }
                        .padding(.top, 24)

                        GlassCard {
                            VStack(alignment: .leading, spacing: 14) {
                                aboutRow(icon: "building.2.fill", label: "Studio", value: "Orbioom")
                                Divider().background(Brand.hairline)
                                aboutRow(icon: "iphone", label: "Platform", value: "iOS 17+")
                                Divider().background(Brand.hairline)
                                aboutRow(icon: "externaldrive.fill", label: "Storage", value: "On-device, SwiftData")
                                Divider().background(Brand.hairline)
                                aboutRow(icon: "lock.fill", label: "Privacy", value: "No data leaves your device")
                                Divider().background(Brand.hairline)
                                aboutRow(icon: "heart.fill", label: "Ads / Paywall", value: "None")
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func aboutRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Brand.live)
                .frame(width: 22)
                .accessibilityHidden(true)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Brand.text2)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Brand.text)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}
