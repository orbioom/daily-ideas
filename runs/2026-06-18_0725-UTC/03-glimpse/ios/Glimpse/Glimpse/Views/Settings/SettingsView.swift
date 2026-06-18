import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @AppStorage("appearance") private var appearanceRaw = AppearanceMode.system.rawValue

    @State private var showPaywall = false
    @State private var reminderDate = Date()
    @State private var reminderDenied = false
    @State private var toast: ToastState?

    var body: some View {
        NavigationStack {
            Form {
                proSection
                appearanceSection
                captureSection
                reminderSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(Theme.rounded(16, .semibold))
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .toast($toast)
            .alert("Notifications are off", isPresented: $reminderDenied) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Enable notifications for Glimpse in the Settings app to receive your daily reminder.")
            }
            .onAppear(perform: syncReminderDate)
            .onChange(of: reminderDate) { _, newValue in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                settings.reminderTime = comps
                if settings.reminderEnabled {
                    Task { await ReminderManager.schedule(hour: comps.hour ?? 20, minute: comps.minute ?? 0) }
                }
            }
        }
    }

    // MARK: - Sections

    private var proSection: some View {
        Section {
            if isPro {
                HStack {
                    Label("Glimpse Pro", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(Theme.good)
                    Spacer()
                    Text("Unlocked").foregroundStyle(Theme.inkSoft)
                }
            } else {
                Button {
                    showPaywall = true
                } label: {
                    HStack {
                        Label("Unlock Glimpse Pro", systemImage: "sparkles")
                            .foregroundStyle(Theme.accent)
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption).foregroundStyle(Theme.inkSoft)
                    }
                }
                Button("Restore purchase") {
                    toast = ToastState(symbol: "info.circle.fill", message: "No purchase to restore")
                }
                .foregroundStyle(Theme.ink)
            }
        } header: {
            Text("Membership")
        }
        .listRowBackground(Theme.surface)
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("Theme", selection: Binding(
                get: { settings.appearance },
                set: { settings.appearance = $0; appearanceRaw = $0.rawValue }
            )) {
                ForEach(AppearanceMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            Toggle(isOn: $settings.hapticsEnabled) {
                Label("Haptics", systemImage: "hand.tap")
            }
            .tint(Theme.accent)
        }
        .listRowBackground(Theme.surface)
    }

    private var captureSection: some View {
        Section("Capture") {
            Picker("Default mood", selection: Binding(
                get: { settings.defaultMood },
                set: { settings.defaultMood = $0 }
            )) {
                ForEach(Mood.allCases) { mood in
                    Label(mood.label, systemImage: mood.symbol).tag(mood)
                }
            }
            Picker("Week starts on", selection: Binding(
                get: { settings.weekStart },
                set: { settings.weekStart = $0 }
            )) {
                ForEach(WeekStart.allCases) { Text($0.rawValue).tag($0) }
            }
            Picker("Grid density", selection: Binding(
                get: { settings.gridDensity },
                set: { settings.gridDensity = $0 }
            )) {
                ForEach(GridDensity.allCases) { Text($0.rawValue).tag($0) }
            }
        }
        .listRowBackground(Theme.surface)
    }

    private var reminderSection: some View {
        Section {
            Toggle(isOn: Binding(
                get: { settings.reminderEnabled },
                set: { newValue in toggleReminder(newValue) }
            )) {
                Label("Daily reminder", systemImage: "bell.badge")
            }
            .tint(Theme.accent)

            if settings.reminderEnabled {
                DatePicker("Remind me at", selection: $reminderDate, displayedComponents: .hourAndMinute)
            }
        } header: {
            Text("Reminder")
        } footer: {
            Text("A gentle nudge to capture today's glimpse. One notification a day, on your schedule.")
        }
        .listRowBackground(Theme.surface)
    }

    private var aboutSection: some View {
        Section("About") {
            LabeledContent("Version", value: appVersion)
            LabeledContent("Storage", value: "On this device")
            NavigationLink {
                aboutDetail
            } label: {
                Label("About Glimpse", systemImage: "info.circle")
            }
        }
        .listRowBackground(Theme.surface)
    }

    private var aboutDetail: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Glimpse")
                    .font(Theme.rounded(26, .bold))
                    .foregroundStyle(Theme.ink)
                Text("A photo-a-day moment journal. Capture one meaningful moment each day — a photo, a line, a mood — and watch a beautiful, private record of your life build up over time.")
                    .font(Theme.bodyFont)
                    .foregroundStyle(Theme.ink.opacity(0.9))
                Text("Your photos and entries never leave your device. No account, no feed, no algorithm — just your days, gathered gently.")
                    .font(Theme.bodyFont)
                    .foregroundStyle(Theme.inkSoft)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var appVersion: String {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let b = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(v) (\(b))"
    }

    // MARK: - Logic

    private func syncReminderDate() {
        let comps = settings.reminderTime
        if let date = Calendar.current.date(bySettingHour: comps.hour ?? 20, minute: comps.minute ?? 0, second: 0, of: Date()) {
            reminderDate = date
        }
    }

    private func toggleReminder(_ enabled: Bool) {
        if enabled {
            Task {
                let granted = await ReminderManager.requestAuthorizationIfNeeded()
                await MainActor.run {
                    if granted {
                        settings.reminderEnabled = true
                        let comps = Calendar.current.dateComponents([.hour, .minute], from: reminderDate)
                        Task { await ReminderManager.schedule(hour: comps.hour ?? 20, minute: comps.minute ?? 0) }
                        toast = ToastState(symbol: "bell.fill", message: "Daily reminder on")
                        Haptics.success(settings.hapticsEnabled)
                    } else {
                        settings.reminderEnabled = false
                        reminderDenied = true
                    }
                }
            }
        } else {
            settings.reminderEnabled = false
            ReminderManager.cancel()
        }
    }
}
