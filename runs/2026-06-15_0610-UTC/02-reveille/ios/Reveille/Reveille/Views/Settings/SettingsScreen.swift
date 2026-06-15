import SwiftUI
import SwiftData

/// Settings: persisted prefs that change behavior, defaults for new alarms, bedside theme,
/// notification status, Pro, data actions, and About.
struct SettingsScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var notifications: NotificationManager
    @AppStorage("isPro") private var isPro = false

    @Query private var alarms: [Alarm]

    @State private var paywallReason: PaywallReason?
    @State private var showResetConfirm = false
    @State private var showAbout = false
    @State private var statusMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                proSection
                behaviorSection
                defaultsSection
                bedsideSection
                notificationsSection
                dataSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Settings")
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
            .sheet(isPresented: $showAbout) { AboutView() }
            .confirmationDialog("Reset wake-up stats?",
                                isPresented: $showResetConfirm,
                                titleVisibility: .visible) {
                Button("Erase & reload sample", role: .destructive) { resetAndReseed() }
                Button("Erase everything", role: .destructive) { eraseAll() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This clears your wake-up history. Your alarms are kept.")
            }
            .task { await notifications.refresh() }
        }
    }

    // MARK: Pro

    private var proSection: some View {
        Section {
            if isPro {
                HStack {
                    Label("Reveille Pro", systemImage: "crown.fill").foregroundStyle(Theme.accent)
                    Spacer()
                    Text("Unlocked").font(Theme.rounded(14, .semibold)).foregroundStyle(Theme.good)
                }
            } else {
                Button { paywallReason = .general } label: {
                    HStack {
                        Label("Unlock Reveille Pro", systemImage: "crown")
                        Spacer()
                        Text(Pro.priceLabel).font(Theme.rounded(14, .semibold)).foregroundStyle(Theme.inkSoft)
                    }
                }
                Text("All missions, all soundscapes, bedside themes, and full stats. One-time, no subscription.")
                    .font(Theme.rounded(12)).foregroundStyle(Theme.inkFaint)
            }
        } header: {
            Text("Reveille Pro")
        }
    }

    // MARK: Behavior prefs (functional, persisted)

    private var behaviorSection: some View {
        Section {
            Toggle(isOn: $settings.hapticsEnabled) {
                Label("Haptics", systemImage: "hand.tap")
            }
            Toggle(isOn: $settings.vibrateOnRing) {
                Label("Vibrate while ringing", systemImage: "iphone.radiowaves.left.and.right")
            }
            Toggle(isOn: $settings.keepScreenOn) {
                Label("Keep screen on", systemImage: "sun.max")
            }
            Toggle(isOn: $settings.use24Hour) {
                Label("24-hour clock", systemImage: "clock")
            }
        } header: {
            Text("Behavior")
        } footer: {
            Text("Keep-screen-on applies to the ring and bedside screens. Reduce Motion is read from your system settings and shortens animations automatically.")
        }
        .tint(Theme.accent)
    }

    // MARK: Defaults for new alarms

    private var defaultsSection: some View {
        Section {
            Picker(selection: $settings.defaultSoundName) {
                ForEach(SoundLibrary.all) { sound in
                    Text(sound.title).tag(sound.id)
                }
            } label: {
                Label("Default sound", systemImage: "speaker.wave.2")
            }
            Stepper(value: $settings.defaultSnoozeMinutes, in: 1...30) {
                HStack {
                    Label("Default snooze", systemImage: "zzz")
                    Spacer()
                    Text("\(settings.safeDefaultSnooze) min").foregroundStyle(Theme.inkSoft)
                }
            }
        } header: {
            Text("New Alarm Defaults")
        } footer: {
            Text("Prefilled when you create a new alarm. A locked sound falls back to a free one until you go Pro.")
        }
    }

    // MARK: Bedside theme

    private var bedsideSection: some View {
        Section {
            ForEach(BedsideTheme.all) { theme in
                Button { selectBedside(theme) } label: {
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(theme.swatch)
                            .frame(width: 28, height: 20)
                            .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Theme.hairline))
                            .accessibilityHidden(true)
                        Text(theme.name).foregroundStyle(Theme.ink)
                        if theme.isPro && !isPro {
                            Image(systemName: "lock.fill").font(.system(size: 11)).foregroundStyle(Theme.inkFaint)
                        }
                        Spacer()
                        if settings.bedsideThemeID == theme.id && !(theme.isPro && !isPro) {
                            Image(systemName: "checkmark").foregroundStyle(Theme.accent)
                        }
                    }
                }
            }
        } header: {
            Text("Bedside Theme")
        } footer: {
            Text(isPro ? "Pick the gradient for your nightstand clock."
                       : "Dawn is free. The other themes are part of Reveille Pro.")
        }
    }

    // MARK: Notifications

    private var notificationsSection: some View {
        Section {
            HStack {
                Label("Backstop notifications", systemImage: "bell.badge")
                Spacer()
                Text(notificationStatusLabel)
                    .font(Theme.rounded(14, .semibold))
                    .foregroundStyle(notificationStatusColor)
            }
            if notifications.authorization != .authorized {
                Button {
                    Task {
                        await notifications.requestAuthorization()
                        notifications.resyncAll(alarms)
                    }
                } label: {
                    Label("Enable notifications", systemImage: "bell.fill")
                }
            }
        } header: {
            Text("Reliability")
        } footer: {
            Text("Reveille rings reliably while it's open or in the background. iOS can't let any third-party app force a custom alarm after it's force-quit, so we also schedule a notification at each alarm time as a backstop.")
        }
    }

    private var notificationStatusLabel: String {
        switch notifications.authorization {
        case .authorized, .provisional, .ephemeral: return "On"
        case .denied: return "Off"
        case .notDetermined: return "Not set"
        @unknown default: return "Unknown"
        }
    }

    private var notificationStatusColor: Color {
        switch notifications.authorization {
        case .authorized, .provisional, .ephemeral: return Theme.good
        case .denied: return Theme.bad
        default: return Theme.inkSoft
        }
    }

    // MARK: Data

    private var dataSection: some View {
        Section {
            Button {
                SeedData.insertSampleWakeLogs(context: context)
                statusMessage = "Sample wake-ups added."
                Haptics.success(settings.hapticsEnabled)
            } label: {
                Label("Load sample wake-ups", systemImage: "tray.and.arrow.down")
            }
            Button(role: .destructive) {
                showResetConfirm = true
            } label: {
                Label("Reset stats", systemImage: "trash")
            }
            if let statusMessage {
                Label(statusMessage, systemImage: "checkmark.circle.fill")
                    .font(Theme.rounded(13)).foregroundStyle(Theme.good)
            }
        } header: {
            Text("Your Data")
        } footer: {
            Text("Everything lives on this device. Nothing is uploaded.")
        }
    }

    private var aboutSection: some View {
        Section {
            Button { showAbout = true } label: {
                Label("About Reveille", systemImage: "info.circle")
            }
            HStack {
                Text("Version"); Spacer()
                Text("1.0").foregroundStyle(Theme.inkSoft)
            }
        }
    }

    // MARK: Actions

    private func selectBedside(_ theme: BedsideTheme) {
        if theme.isPro && !isPro {
            paywallReason = .bedsideTheme
        } else {
            settings.bedsideThemeID = theme.id
            Haptics.select(settings.hapticsEnabled)
        }
    }

    private func resetAndReseed() {
        SeedData.clearWakeLogs(context: context)
        SeedData.insertSampleWakeLogs(context: context)
        statusMessage = "Stats reset and sample reloaded."
        Haptics.success(settings.hapticsEnabled)
    }

    private func eraseAll() {
        SeedData.clearWakeLogs(context: context)
        statusMessage = "All wake-up stats erased."
        Haptics.warning(settings.hapticsEnabled)
    }
}
