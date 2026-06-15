import SwiftUI
import SwiftData

/// Create or edit an alarm. Editing mutates the existing model in place; creating inserts a
/// new one. All Pro-gated choices (premium missions/sounds) route to the paywall and fall back
/// to a free option rather than persisting a locked value.
struct AlarmEditScreen: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var notifications: NotificationManager
    @AppStorage("isPro") private var isPro = false

    /// The alarm being edited, or nil to create a new one.
    let alarm: Alarm?

    // Editable state
    @State private var timeDate: Date
    @State private var repeatDays: Set<Int>
    @State private var label: String
    @State private var soundName: String
    @State private var missionType: MissionType
    @State private var missionDifficulty: MissionDifficulty
    @State private var missionReps: Int
    @State private var snoozeEnabled: Bool
    @State private var snoozeMinutes: Int
    @State private var maxSnoozes: Int
    @State private var volumeRampSeconds: Int

    @State private var paywallReason: PaywallReason?
    @StateObject private var previewEngine = RingEngine()

    init(alarm: Alarm?) {
        self.alarm = alarm
        let cal = Calendar.current
        if let alarm {
            var comps = DateComponents()
            comps.hour = alarm.hour; comps.minute = alarm.minute
            _timeDate = State(initialValue: cal.date(from: comps) ?? Date())
            _repeatDays = State(initialValue: alarm.repeatSet)
            _label = State(initialValue: alarm.label)
            _soundName = State(initialValue: alarm.soundName)
            _missionType = State(initialValue: alarm.missionType)
            _missionDifficulty = State(initialValue: alarm.missionDifficulty)
            _missionReps = State(initialValue: alarm.missionReps)
            _snoozeEnabled = State(initialValue: alarm.snoozeEnabled)
            _snoozeMinutes = State(initialValue: alarm.snoozeMinutes)
            _maxSnoozes = State(initialValue: alarm.maxSnoozes)
            _volumeRampSeconds = State(initialValue: alarm.volumeRampSeconds)
        } else {
            // New alarm defaults pull from Settings.
            var comps = DateComponents(); comps.hour = 7; comps.minute = 0
            _timeDate = State(initialValue: cal.date(from: comps) ?? Date())
            _repeatDays = State(initialValue: [])
            _label = State(initialValue: "Wake up")
            _soundName = State(initialValue: UserDefaults.standard.string(forKey: "defaultSoundName") ?? SoundLibrary.defaultSoundName)
            _missionType = State(initialValue: .math)
            _missionDifficulty = State(initialValue: .medium)
            _missionReps = State(initialValue: 3)
            _snoozeEnabled = State(initialValue: true)
            _snoozeMinutes = State(initialValue: max(1, UserDefaults.standard.integer(forKey: "defaultSnoozeMinutes") == 0 ? 9 : UserDefaults.standard.integer(forKey: "defaultSnoozeMinutes")))
            _maxSnoozes = State(initialValue: 3)
            _volumeRampSeconds = State(initialValue: 20)
        }
    }

    private var isEditing: Bool { alarm != nil }

    var body: some View {
        NavigationStack {
            Form {
                timeSection
                repeatSection
                labelSection
                soundSection
                missionSection
                snoozeSection
                rampSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle(isEditing ? "Edit Alarm" : "New Alarm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { previewEngine.stop(); dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }.fontWeight(.semibold)
                }
            }
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
            .onDisappear { previewEngine.stop() }
        }
    }

    // MARK: Time

    private var timeSection: some View {
        Section {
            DatePicker("Time", selection: $timeDate, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(maxWidth: .infinity)
                .environment(\.locale, settings.use24Hour ? Locale(identifier: "en_GB") : Locale(identifier: "en_US"))
        }
    }

    // MARK: Repeat

    private var repeatSection: some View {
        Section {
            HStack(spacing: 8) {
                ForEach(Weekday.pickerOrder) { day in
                    let on = repeatDays.contains(day.rawValue)
                    Button {
                        toggleDay(day.rawValue)
                    } label: {
                        Text(day.letter)
                            .font(Theme.rounded(15, .semibold))
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(on ? Theme.accent : Theme.surfaceAlt))
                            .foregroundStyle(on ? .white : Theme.inkSoft)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(day.short)
                    .accessibilityValue(on ? "Repeats" : "Off")
                }
            }
            .frame(maxWidth: .infinity)
            Text(AlarmScheduler.repeatSummary(Array(repeatDays)))
                .font(Theme.rounded(13))
                .foregroundStyle(Theme.inkSoft)
                .frame(maxWidth: .infinity, alignment: .center)
        } header: {
            Text("Repeat")
        } footer: {
            Text("No days selected means the alarm rings once at the next occurrence, then turns itself off.")
        }
    }

    // MARK: Label

    private var labelSection: some View {
        Section("Label") {
            TextField("Alarm name", text: $label)
                .font(Theme.rounded(16))
                .submitLabel(.done)
        }
    }

    // MARK: Sound

    private var soundSection: some View {
        Section {
            ForEach(SoundLibrary.all) { sound in
                Button {
                    selectSound(sound)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: sound.symbol)
                            .foregroundStyle(Theme.accent)
                            .frame(width: 26)
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(sound.title).foregroundStyle(Theme.ink)
                                if !sound.isFree && !isPro { ProBadge() }
                            }
                            Text(sound.blurb)
                                .font(Theme.rounded(12))
                                .foregroundStyle(Theme.inkFaint)
                                .lineLimit(1)
                        }
                        Spacer()
                        if soundName == sound.id {
                            Image(systemName: "checkmark").foregroundStyle(Theme.accent)
                        }
                        Button {
                            previewEngine.preview(soundName: sound.id)
                            Haptics.tap(settings.hapticsEnabled)
                        } label: {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(Theme.accent.opacity(0.85))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Preview \(sound.title)")
                    }
                }
                .buttonStyle(.plain)
            }
        } header: {
            Text("Sound")
        } footer: {
            Text("Every tone is synthesized live on your device — no audio files. Tap the play icon to preview.")
        }
    }

    // MARK: Mission

    private var missionSection: some View {
        Section {
            ForEach(MissionType.allCases) { type in
                Button {
                    selectMission(type)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: type.symbol)
                            .foregroundStyle(Theme.accent)
                            .frame(width: 26)
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(type.title).foregroundStyle(Theme.ink)
                                if !type.isFree && !isPro { ProBadge() }
                            }
                            Text(type.detail)
                                .font(Theme.rounded(12))
                                .foregroundStyle(Theme.inkFaint)
                                .lineLimit(2)
                        }
                        Spacer()
                        if missionType == type {
                            Image(systemName: "checkmark").foregroundStyle(Theme.accent)
                        }
                    }
                }
                .buttonStyle(.plain)
            }

            if missionType != .none {
                Picker("Difficulty", selection: $missionDifficulty) {
                    ForEach(MissionDifficulty.allCases) { d in
                        Text(d.title).tag(d)
                    }
                }
                .pickerStyle(.segmented)

                Stepper(value: $missionReps, in: 1...10) {
                    HStack {
                        Text("Repetitions")
                        Spacer()
                        Text("\(missionReps)×").foregroundStyle(Theme.inkSoft)
                    }
                }
            }
        } header: {
            Text("Dismiss Mission")
        } footer: {
            Text(missionType == .none
                 ? "A single Stop button. Best for light sleepers who don't need a challenge."
                 : "Finish all repetitions to silence the alarm. Math and Shake are free; the rest are Reveille Pro.")
        }
    }

    // MARK: Snooze

    private var snoozeSection: some View {
        Section {
            Toggle("Allow snooze", isOn: $snoozeEnabled).tint(Theme.accent)
            if snoozeEnabled {
                Stepper(value: $snoozeMinutes, in: 1...30) {
                    HStack { Text("Snooze length"); Spacer()
                        Text("\(snoozeMinutes) min").foregroundStyle(Theme.inkSoft) }
                }
                Stepper(value: $maxSnoozes, in: 0...10) {
                    HStack { Text("Max snoozes"); Spacer()
                        Text(maxSnoozes == 0 ? "None" : "\(maxSnoozes)").foregroundStyle(Theme.inkSoft) }
                }
            }
        } header: {
            Text("Snooze")
        } footer: {
            Text("Reveille caps how many times you can snooze, so you can't snooze forever. Every snooze is logged in your stats.")
        }
    }

    // MARK: Volume ramp

    private var rampSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Fade-in")
                    Spacer()
                    Text(volumeRampSeconds == 0 ? "Instant" : "\(volumeRampSeconds)s")
                        .foregroundStyle(Theme.inkSoft)
                }
                Slider(value: Binding(
                    get: { Double(volumeRampSeconds) },
                    set: { volumeRampSeconds = Int($0.rounded()) }
                ), in: 0...120, step: 5)
                .tint(Theme.accent)
                .accessibilityValue("\(volumeRampSeconds) seconds")
            }
        } header: {
            Text("Volume Ramp")
        } footer: {
            Text("The alarm starts quiet and rises to full over this many seconds — a gentler way to wake.")
        }
    }

    // MARK: Selection helpers (Pro gating)

    private func toggleDay(_ day: Int) {
        Haptics.select(settings.hapticsEnabled)
        if repeatDays.contains(day) { repeatDays.remove(day) } else { repeatDays.insert(day) }
    }

    private func selectSound(_ sound: AlarmSound) {
        if !sound.isFree && !isPro {
            paywallReason = .sound(sound.id)
            return
        }
        Haptics.select(settings.hapticsEnabled)
        soundName = sound.id
        previewEngine.preview(soundName: sound.id)
    }

    private func selectMission(_ type: MissionType) {
        if !type.isFree && !isPro {
            paywallReason = .mission(type)
            return
        }
        Haptics.select(settings.hapticsEnabled)
        missionType = type
    }

    // MARK: Save

    private func save() {
        previewEngine.stop()
        let cal = Calendar.current
        let comps = cal.dateComponents([.hour, .minute], from: timeDate)
        let hour = comps.hour ?? 7
        let minute = comps.minute ?? 0
        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalLabel = trimmed.isEmpty ? "Alarm" : trimmed

        // Coerce locked choices to free fallbacks (defensive — UI already gates, but be safe).
        let safeSound = (!isPro && !SoundLibrary.sound(named: soundName).isFree) ? SoundLibrary.defaultSoundName : soundName
        let safeMission = (!isPro && !missionType.isFree) ? MissionType.math : missionType

        if let alarm {
            alarm.hour = hour
            alarm.minute = minute
            alarm.repeatSet = repeatDays
            alarm.label = finalLabel
            alarm.soundName = safeSound
            alarm.missionType = safeMission
            alarm.missionDifficulty = missionDifficulty
            alarm.missionReps = missionReps
            alarm.snoozeEnabled = snoozeEnabled
            alarm.snoozeMinutes = snoozeMinutes
            alarm.maxSnoozes = maxSnoozes
            alarm.volumeRampSeconds = volumeRampSeconds
            alarm.isEnabled = true
            try? context.save()
            notifications.scheduleBackstop(for: alarm)
        } else {
            let new = Alarm(hour: hour, minute: minute,
                            repeatDays: Array(repeatDays), label: finalLabel,
                            soundName: safeSound, missionType: safeMission,
                            missionDifficulty: missionDifficulty, missionReps: missionReps,
                            snoozeEnabled: snoozeEnabled, snoozeMinutes: snoozeMinutes,
                            maxSnoozes: maxSnoozes, volumeRampSeconds: volumeRampSeconds,
                            isEnabled: true)
            context.insert(new)
            try? context.save()
            notifications.scheduleBackstop(for: new)
        }
        Haptics.success(settings.hapticsEnabled)
        dismiss()
    }
}
