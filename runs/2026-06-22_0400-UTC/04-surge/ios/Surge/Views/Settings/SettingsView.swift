import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var settingsArray: [SurgeSettings]
    @Query private var profiles: [RunnerProfile]
    @Environment(\.modelContext) private var modelContext
    @State private var showingResetConfirm: Bool = false

    private var settings: SurgeSettings? { settingsArray.first }
    private var profile: RunnerProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if let profile = profile {
                        profileSection(profile)
                    }
                    unitSection
                    preferencesSection
                    aboutSection
                    dangerSection
                }
                .padding(16)
                .padding(.bottom, 40)
            }
            .background(Color.surgeBackground.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
        .confirmationDialog(
            "Reset Training Plan",
            isPresented: $showingResetConfirm,
            titleVisibility: .visible
        ) {
            Button("Reset Everything", role: .destructive) { resetAll() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will delete your training plan and all run logs. This cannot be undone.")
        }
    }

    private func profileSection(_ profile: RunnerProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SurgeSectionHeader(title: "Training Profile")
            VStack(spacing: 0) {
                settingsRow(icon: "figure.run", label: "Race", value: profile.raceType.displayName)
                Divider().background(Color.surgeDivider).padding(.leading, 52)
                settingsRow(icon: "clock", label: "Goal Time", value: PaceEngine.formatGoalTime(profile.goalTimeSeconds))
                Divider().background(Color.surgeDivider).padding(.leading, 52)
                settingsRow(icon: "calendar", label: "Week", value: "Week \(profile.currentWeekNumber) of \(profile.totalWeeks)")
                if let raceDate = profile.raceDateTarget {
                    Divider().background(Color.surgeDivider).padding(.leading, 52)
                    settingsRow(icon: "flag.checkered", label: "Race Date", value: raceDate.formatted(date: .abbreviated, time: .omitted))
                }
            }
            .surgeCard(padding: 0)
        }
    }

    private var unitSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SurgeSectionHeader(title: "Distance Units")
            HStack(spacing: 10) {
                UnitButton(label: "Kilometers", sublabel: "km", isSelected: settings?.unit == "km") {
                    settings?.unit = "km"
                    try? modelContext.save()
                }
                UnitButton(label: "Miles", sublabel: "mi", isSelected: settings?.unit == "mi") {
                    settings?.unit = "mi"
                    try? modelContext.save()
                }
            }
        }
    }

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SurgeSectionHeader(title: "Preferences")
            VStack(spacing: 0) {
                if let settings = settings {
                    Toggle(isOn: Binding(
                        get: { settings.hapticsEnabled },
                        set: { settings.hapticsEnabled = $0; try? modelContext.save() }
                    )) {
                        HStack(spacing: 12) {
                            Image(systemName: "hand.tap.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.surgeAccent)
                                .frame(width: 28)
                            Text("Haptic Feedback")
                                .font(.surgeBody)
                                .foregroundColor(.surgeTextPrimary)
                        }
                    }
                    .tint(.surgeAccent)
                    .padding(16)

                    Divider().background(Color.surgeDivider).padding(.leading, 56)

                    Toggle(isOn: Binding(
                        get: { settings.notificationsEnabled },
                        set: { settings.notificationsEnabled = $0; try? modelContext.save() }
                    )) {
                        HStack(spacing: 12) {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.surgeHighlight)
                                .frame(width: 28)
                            Text("Daily Reminders")
                                .font(.surgeBody)
                                .foregroundColor(.surgeTextPrimary)
                        }
                    }
                    .tint(.surgeAccent)
                    .padding(16)

                    if settings.notificationsEnabled {
                        Divider().background(Color.surgeDivider).padding(.leading, 56)
                        HStack {
                            HStack(spacing: 12) {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.surgeTextSecondary)
                                    .frame(width: 28)
                                Text("Reminder Time")
                                    .font(.surgeBody)
                                    .foregroundColor(.surgeTextPrimary)
                            }
                            Spacer()
                            DatePicker(
                                "Reminder",
                                selection: Binding(
                                    get: {
                                        var comps = DateComponents()
                                        comps.hour = settings.reminderHour
                                        comps.minute = settings.reminderMinute
                                        return Calendar.current.date(from: comps) ?? Date()
                                    },
                                    set: { date in
                                        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
                                        settings.reminderHour = comps.hour ?? 7
                                        settings.reminderMinute = comps.minute ?? 0
                                        try? modelContext.save()
                                    }
                                ),
                                displayedComponents: .hourAndMinute
                            )
                            .labelsHidden()
                            .tint(.surgeAccent)
                        }
                        .padding(16)
                    }
                }
            }
            .surgeCard(padding: 0)
        }
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SurgeSectionHeader(title: "About")
            VStack(spacing: 0) {
                settingsRow(icon: "bolt.fill", label: "Surge", value: "Version 1.0")
                Divider().background(Color.surgeDivider).padding(.leading, 52)
                settingsRow(icon: "heart.fill", label: "Made with", value: "Swift & SwiftUI")
                Divider().background(Color.surgeDivider).padding(.leading, 52)
                settingsRow(icon: "figure.run.circle", label: "Plans", value: "Higdon-Inspired")
            }
            .surgeCard(padding: 0)
        }
    }

    private var dangerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SurgeSectionHeader(title: "Data")
            Button(action: { showingResetConfirm = true }) {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.counterclockwise.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color(red: 0.95, green: 0.2, blue: 0.2))
                    Text("Reset Training Plan")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(red: 0.95, green: 0.2, blue: 0.2))
                    Spacer()
                }
                .padding(16)
                .surgeCard(padding: 0)
            }
            .buttonStyle(.plain)
        }
    }

    private func settingsRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.surgeAccent)
                .frame(width: 28)
            Text(label)
                .font(.surgeBody)
                .foregroundColor(.surgeTextPrimary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.surgeTextSecondary)
        }
        .padding(16)
    }

    private func resetAll() {
        let profileDesc = FetchDescriptor<RunnerProfile>()
        let planDesc = FetchDescriptor<PlannedRun>()
        let logDesc = FetchDescriptor<RunLog>()
        if let profiles = try? modelContext.fetch(profileDesc) { profiles.forEach { modelContext.delete($0) } }
        if let plans = try? modelContext.fetch(planDesc) { plans.forEach { modelContext.delete($0) } }
        if let logs = try? modelContext.fetch(logDesc) { logs.forEach { modelContext.delete($0) } }
        try? modelContext.save()
    }
}

struct UnitButton: View {
    let label: String
    let sublabel: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Text(sublabel)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(isSelected ? .white : .surgeTextSecondary)
                Text(label)
                    .font(.surgeCaption)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .surgeTextSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? Color.surgeAccent : Color.surgeSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? Color.surgeAccent : Color.surgeDivider, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
