import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var schedules: [UserSchedule]
    @Query private var records: [BreakRecord]
    @Environment(\.modelContext) private var modelContext
    @Environment(BreakScheduler.self) private var scheduler
    @State private var showingProSheet = false
    @State private var showingClearConfirm = false
    @State private var isRequestingPermission = false

    private var schedule: UserSchedule {
        if let s = schedules.first { return s }
        let s = UserSchedule()
        modelContext.insert(s)
        return s
    }

    private let dayLabels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Pro card
                    proCard

                    // Break interval
                    settingsSection(title: "Break Schedule") {
                        pickerRow(
                            label: "Break Interval",
                            subtitle: "How often to remind you",
                            value: schedule.intervalMinutes,
                            options: [20, 30, 45, 60],
                            format: { "\($0) min" }
                        ) { newVal in
                            schedule.intervalMinutes = newVal
                            scheduler.scheduleBreaks(schedule: schedule)
                        }

                        Divider().padding(.vertical, 2)

                        pickerRow(
                            label: "Break Duration",
                            subtitle: "Time for each break session",
                            value: schedule.breakDurationSeconds,
                            options: [60, 120, 180, 300],
                            format: { $0 < 60 ? "\($0)s" : "\($0 / 60) min" }
                        ) { schedule.breakDurationSeconds = $0 }

                        Divider().padding(.vertical, 2)

                        hourPickerRow(
                            label: "Work Hours Start",
                            hour: schedule.startHour
                        ) { schedule.startHour = $0 }

                        Divider().padding(.vertical, 2)

                        hourPickerRow(
                            label: "Work Hours End",
                            hour: schedule.endHour
                        ) { schedule.endHour = $0 }
                    }

                    // Active days
                    settingsSection(title: "Active Days") {
                        HStack(spacing: 6) {
                            ForEach(Array(dayLabels.enumerated()), id: \.offset) { index, day in
                                let enabled = schedule.enabledDaysArray.indices.contains(index) ? schedule.enabledDaysArray[index] : true
                                Button {
                                    var days = schedule.enabledDaysArray
                                    if days.indices.contains(index) {
                                        days[index] = !days[index]
                                        schedule.enabledDaysArray = days
                                        scheduler.scheduleBreaks(schedule: schedule)
                                    }
                                } label: {
                                    Text(day)
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(enabled ? .white : PoiseTheme.textMuted)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(enabled ? PoiseTheme.sky : PoiseTheme.backgroundTertiary)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                    }

                    // Exercise categories
                    settingsSection(title: "Exercise Categories") {
                        VStack(spacing: 10) {
                            ForEach(ExerciseCategory.allCases) { cat in
                                let enabled = schedule.exerciseCategoriesArray.contains(cat.rawValue.lowercased())
                                Toggle(isOn: Binding(
                                    get: { enabled },
                                    set: { newVal in
                                        var cats = schedule.exerciseCategoriesArray
                                        if newVal {
                                            if !cats.contains(cat.rawValue.lowercased()) {
                                                cats.append(cat.rawValue.lowercased())
                                            }
                                        } else {
                                            cats.removeAll { $0 == cat.rawValue.lowercased() }
                                        }
                                        schedule.exerciseCategoriesArray = cats
                                    }
                                )) {
                                    Label(cat.rawValue, systemImage: cat.icon)
                                        .foregroundColor(enabled ? PoiseTheme.categoryColor(for: cat) : PoiseTheme.textMuted)
                                }
                                .tint(PoiseTheme.sky)
                            }
                        }
                    }

                    // Notifications
                    settingsSection(title: "Notifications") {
                        Toggle(isOn: Binding(
                            get: { schedule.remindersEnabled },
                            set: { newVal in
                                schedule.remindersEnabled = newVal
                                if newVal {
                                    scheduler.scheduleBreaks(schedule: schedule)
                                } else {
                                    scheduler.cancelAllBreaks()
                                }
                            }
                        )) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Break Reminders")
                                    .font(.subheadline)
                                    .foregroundColor(PoiseTheme.textPrimary)
                                Text("Get notified when it's time to stretch")
                                    .font(.caption)
                                    .foregroundColor(PoiseTheme.textSecondary)
                            }
                        }
                        .tint(PoiseTheme.sky)

                        Divider().padding(.vertical, 2)

                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Permission Status")
                                    .font(.subheadline)
                                    .foregroundColor(PoiseTheme.textPrimary)
                                Text(permissionStatusLabel)
                                    .font(.caption)
                                    .foregroundColor(permissionStatusColor)
                            }
                            Spacer()
                            if !scheduler.isPermissionGranted {
                                Button {
                                    isRequestingPermission = true
                                    Task {
                                        let granted = await scheduler.requestPermission()
                                        if granted {
                                            scheduler.scheduleBreaks(schedule: schedule)
                                        }
                                        isRequestingPermission = false
                                    }
                                } label: {
                                    Text(isRequestingPermission ? "Requesting..." : "Allow")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(PoiseTheme.sky)
                                        .clipShape(Capsule())
                                }
                                .disabled(isRequestingPermission)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                    }

                    // Feedback
                    settingsSection(title: "Feedback") {
                        Toggle(isOn: Binding(
                            get: { schedule.hapticsEnabled },
                            set: { schedule.hapticsEnabled = $0 }
                        )) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Haptic Feedback")
                                    .font(.subheadline)
                                    .foregroundColor(PoiseTheme.textPrimary)
                                Text("Vibrate on exercise transitions")
                                    .font(.caption)
                                    .foregroundColor(PoiseTheme.textSecondary)
                            }
                        }
                        .tint(PoiseTheme.sky)

                        Divider().padding(.vertical, 2)

                        Toggle(isOn: Binding(
                            get: { schedule.soundEnabled },
                            set: { schedule.soundEnabled = $0 }
                        )) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Sounds")
                                    .font(.subheadline)
                                    .foregroundColor(PoiseTheme.textPrimary)
                                Text("Play audio cues during breaks")
                                    .font(.caption)
                                    .foregroundColor(PoiseTheme.textSecondary)
                            }
                        }
                        .tint(PoiseTheme.sky)
                    }

                    // Daily goal
                    settingsSection(title: "Goals") {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Daily Break Goal")
                                    .font(.subheadline)
                                    .foregroundColor(PoiseTheme.textPrimary)
                                Text("Target breaks per day")
                                    .font(.caption)
                                    .foregroundColor(PoiseTheme.textSecondary)
                            }
                            Spacer()
                            Stepper("\(schedule.dailyBreakGoal)", value: Binding(
                                get: { schedule.dailyBreakGoal },
                                set: { schedule.dailyBreakGoal = max(1, min(24, $0)) }
                            ))
                            .labelsHidden()
                            .foregroundColor(PoiseTheme.textPrimary)
                            Text("\(schedule.dailyBreakGoal)")
                                .font(.headline)
                                .foregroundColor(PoiseTheme.sky)
                                .frame(width: 28)
                        }
                    }

                    // Data
                    settingsSection(title: "Data") {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Break History")
                                    .font(.subheadline)
                                    .foregroundColor(PoiseTheme.textPrimary)
                                Text("\(records.count) sessions recorded")
                                    .font(.caption)
                                    .foregroundColor(PoiseTheme.textMuted)
                            }
                            Spacer()
                            Button("Clear") {
                                showingClearConfirm = true
                            }
                            .font(.subheadline)
                            .foregroundColor(.red)
                        }
                    }

                    // About
                    VStack(spacing: 6) {
                        Text("Poise — Posture & Ergonomics Coach")
                            .font(.caption)
                            .foregroundColor(PoiseTheme.textMuted)
                        Text("v1.0  •  com.orbioom.poise")
                            .font(.caption2)
                            .foregroundColor(PoiseTheme.textMuted.opacity(0.6))
                        Text("Your health data stays on your device. No sign-in required.")
                            .font(.caption2)
                            .foregroundColor(PoiseTheme.textMuted.opacity(0.5))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.bottom, 24)
                }
                .padding(.bottom, 16)
            }
            .navigationTitle("Settings")
            .background(PoiseTheme.backgroundSecondary)
            .sheet(isPresented: $showingProSheet) {
                PoiseProView(schedule: schedule)
            }
            .confirmationDialog("Clear History?", isPresented: $showingClearConfirm, titleVisibility: .visible) {
                Button("Clear All History", role: .destructive) {
                    for record in records {
                        modelContext.delete(record)
                    }
                    schedule.totalBreaksTaken = 0
                    schedule.currentStreakDays = 0
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently deletes \(records.count) break records and resets your stats.")
            }
        }
    }

    private var permissionStatusLabel: String {
        switch scheduler.permissionStatus {
        case .authorized: return "Allowed"
        case .denied: return "Denied — change in Settings app"
        case .notDetermined: return "Not yet requested"
        case .provisional: return "Provisional"
        case .ephemeral: return "Ephemeral"
        @unknown default: return "Unknown"
        }
    }

    private var permissionStatusColor: Color {
        switch scheduler.permissionStatus {
        case .authorized: return .green
        case .denied: return .red
        default: return PoiseTheme.textMuted
        }
    }

    private var proCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "star.circle.fill")
                    .foregroundColor(schedule.isPro ? PoiseTheme.sky : PoiseTheme.textMuted)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(schedule.isPro ? "Poise Pro — Active" : "Poise Pro")
                        .font(.headline)
                        .foregroundColor(PoiseTheme.textPrimary)
                    Text(schedule.isPro ? "All features unlocked" : "Advanced programs + charts")
                        .font(.caption)
                        .foregroundColor(PoiseTheme.textMuted)
                }
                Spacer()
                if !schedule.isPro {
                    Text("$2.99")
                        .font(.headline)
                        .foregroundColor(PoiseTheme.sky)
                }
            }

            if !schedule.isPro {
                Button { showingProSheet = true } label: {
                    Text("Upgrade to Pro — $2.99")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(PoiseTheme.skyGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(16)
        .background(PoiseTheme.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(schedule.isPro ? PoiseTheme.sky.opacity(0.4) : Color(.separator), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundColor(PoiseTheme.textMuted)
                .kerning(1)
                .padding(.horizontal, 20)

            VStack(spacing: 12) {
                content()
            }
            .padding(16)
            .background(PoiseTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 20)
        }
    }

    private func pickerRow<T: Equatable>(
        label: String,
        subtitle: String,
        value: T,
        options: [T],
        format: @escaping (T) -> String,
        onChange: @escaping (T) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(PoiseTheme.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(PoiseTheme.textSecondary)
            }
            HStack(spacing: 8) {
                ForEach(options, id: \.self) { option in
                    Button { onChange(option) } label: {
                        Text(format(option))
                            .font(.caption.weight(.semibold))
                            .foregroundColor(option == value ? .white : PoiseTheme.textPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(option == value ? PoiseTheme.sky : PoiseTheme.backgroundTertiary)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    private func hourPickerRow(label: String, hour: Int, onChange: @escaping (Int) -> Void) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(PoiseTheme.textPrimary)
            Spacer()
            Picker("", selection: Binding(get: { hour }, set: onChange)) {
                ForEach(6..<23) { h in
                    Text(formatHour(h)).tag(h)
                }
            }
            .labelsHidden()
            .tint(PoiseTheme.sky)
        }
    }

    private func formatHour(_ hour: Int) -> String {
        let ampm = hour < 12 ? "AM" : "PM"
        let h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        return "\(h):00 \(ampm)"
    }
}

struct PoiseProView: View {
    let schedule: UserSchedule
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 12) {
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 72))
                            .foregroundColor(PoiseTheme.sky)

                        Text("Poise Pro")
                            .font(.largeTitle.weight(.bold))
                            .foregroundColor(PoiseTheme.textPrimary)

                        Text("One-time purchase • No subscription • No ads")
                            .font(.subheadline)
                            .foregroundColor(PoiseTheme.textSecondary)
                    }
                    .padding(.top, 20)

                    VStack(spacing: 0) {
                        proFeatureRow(
                            icon: "calendar.badge.checkmark",
                            title: "Custom Programs",
                            body: "Build personalized exercise routines with custom timing and sequences."
                        )
                        Divider()
                        proFeatureRow(
                            icon: "bell.badge.fill",
                            title: "Advanced Scheduling",
                            body: "Set multiple break windows per day, focus mode overrides, and smart reminders."
                        )
                        Divider()
                        proFeatureRow(
                            icon: "chart.xyaxis.line",
                            title: "Advanced Analytics",
                            body: "Full usage charts, weekly reports, and adherence trends over time."
                        )
                    }
                    .background(PoiseTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    VStack(spacing: 12) {
                        Button {
                            // StoreKit purchase
                            schedule.isPro = true
                            dismiss()
                        } label: {
                            Text("Purchase for $2.99")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(PoiseTheme.skyGradient)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        Button("Restore Purchase") {}
                            .font(.subheadline)
                            .foregroundColor(PoiseTheme.textSecondary)
                    }

                    Text("Payment processed by Apple. Non-refundable.")
                        .font(.caption2)
                        .foregroundColor(PoiseTheme.textMuted)
                        .padding(.bottom, 24)
                }
                .padding(.horizontal, 24)
            }
            .background(PoiseTheme.backgroundSecondary)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func proFeatureRow(icon: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .foregroundColor(PoiseTheme.sky)
                .font(.title3)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(PoiseTheme.textPrimary)
                Text(body)
                    .font(.caption)
                    .foregroundColor(PoiseTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
    }
}
