import SwiftUI
import SwiftData

/// Create or edit a single night. Validates that the night isn't in the future
/// and that the duration is plausible before saving.
struct LogEditorView: View {
    enum Mode {
        case create
        case edit(SleepLog)
    }

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var settingsList: [SleepSettings]

    let mode: Mode

    @State private var night: Date
    @State private var bedTime: Date
    @State private var wakeTime: Date
    @State private var quality: Int
    @State private var awakenings: Int
    @State private var note: String
    @State private var tagText: String
    @State private var errorMessage: String?
    @State private var showSaved = false

    private var use24h: Bool { settingsList.first?.use24HourClock ?? false }
    private var hapticsOn: Bool { settingsList.first?.hapticsEnabled ?? true }

    init(mode: Mode) {
        self.mode = mode
        switch mode {
        case .create:
            let cal = Calendar.current
            let today = cal.startOfDay(for: .now)
            let defaultBed = cal.date(byAdding: .day, value: -1, to: cal.date(bySettingHour: 23, minute: 15, second: 0, of: today) ?? today) ?? today
            _night = State(initialValue: today)
            _bedTime = State(initialValue: defaultBed)
            _wakeTime = State(initialValue: cal.date(bySettingHour: 7, minute: 0, second: 0, of: today) ?? today)
            _quality = State(initialValue: 4)
            _awakenings = State(initialValue: 0)
            _note = State(initialValue: "")
            _tagText = State(initialValue: "")
        case .edit(let log):
            _night = State(initialValue: log.night)
            _bedTime = State(initialValue: log.bedTime)
            _wakeTime = State(initialValue: log.wakeTime)
            _quality = State(initialValue: log.quality)
            _awakenings = State(initialValue: log.awakenings)
            _note = State(initialValue: log.note)
            _tagText = State(initialValue: log.tags.joined(separator: ", "))
        }
    }

    private var computedDuration: Double {
        let secs = wakeTime.timeIntervalSince(bedTime)
        let adjusted = secs >= 0 ? secs : secs + 86_400
        return max(0, adjusted) / 3600.0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Night") {
                    DatePicker("Woke on", selection: $night, in: ...Date.now, displayedComponents: .date)
                }

                Section("Times") {
                    DatePicker("In bed", selection: $bedTime, displayedComponents: [.date, .hourAndMinute])
                    DatePicker("Woke", selection: $wakeTime, displayedComponents: [.date, .hourAndMinute])
                    HStack {
                        Text("Time in bed")
                        Spacer()
                        Text(Format.duration(computedDuration))
                            .foregroundStyle(durationColor)
                            .font(.body.weight(.semibold))
                    }
                    .accessibilityElement(children: .combine)
                }

                Section("How was it?") {
                    qualityPicker
                    Stepper(value: $awakenings, in: 0...20) {
                        HStack {
                            Text("Wake-ups")
                            Spacer()
                            Text("\(awakenings)").foregroundStyle(Theme.textSecondary)
                        }
                    }
                }

                Section("Tags") {
                    TextField("e.g. caffeine, screen, exercise", text: $tagText, axis: .vertical)
                        .autocorrectionDisabled()
                    if !parsedTags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(parsedTags, id: \.self) { tag in
                                    Text("#\(tag)")
                                        .font(.caption)
                                        .padding(.horizontal, 8).padding(.vertical, 4)
                                        .background(Theme.dusk.opacity(0.15))
                                        .clipShape(Capsule())
                                        .foregroundStyle(Theme.dusk)
                                }
                            }
                        }
                    }
                }

                Section("Note") {
                    TextField("Anything notable about last night…", text: $note, axis: .vertical)
                        .lineLimit(2...5)
                }

                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(Theme.bad)
                            .font(.subheadline)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Night" : "Log a Night")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
        }
    }

    private var qualityPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quality")
                .font(.subheadline)
            HStack(spacing: 10) {
                ForEach(1...5, id: \.self) { value in
                    Button {
                        quality = value
                        Haptics.tap(hapticsOn)
                    } label: {
                        Image(systemName: value <= quality ? "star.fill" : "star")
                            .font(.title3)
                            .foregroundStyle(value <= quality ? Theme.warn : Theme.textSecondary.opacity(0.4))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(value) star\(value == 1 ? "" : "s")")
                    .accessibilityAddTraits(value == quality ? [.isSelected, .isButton] : .isButton)
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var durationColor: Color {
        switch computedDuration {
        case ..<4: return Theme.bad
        case 4..<6: return Theme.warn
        default: return Theme.good
        }
    }

    private var parsedTags: [String] {
        tagText
            .split(whereSeparator: { $0 == "," || $0 == " " })
            .map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
            .filter { !$0.isEmpty }
            .reduce(into: [String]()) { acc, tag in if !acc.contains(tag) { acc.append(tag) } }
    }

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private func save() {
        // Validation
        guard computedDuration > 0 else {
            errorMessage = "Wake time must be after bed time."
            Haptics.warning(hapticsOn)
            return
        }
        guard computedDuration <= 18 else {
            errorMessage = "That's over 18 hours in bed — please check the times."
            Haptics.warning(hapticsOn)
            return
        }
        guard night <= Date.now else {
            errorMessage = "You can't log a night in the future."
            Haptics.warning(hapticsOn)
            return
        }

        switch mode {
        case .create:
            let log = SleepLog(
                night: Calendar.current.startOfDay(for: night),
                bedTime: bedTime,
                wakeTime: wakeTime,
                quality: quality,
                awakenings: awakenings,
                note: note.trimmingCharacters(in: .whitespacesAndNewlines),
                tags: parsedTags
            )
            context.insert(log)
        case .edit(let log):
            log.night = Calendar.current.startOfDay(for: night)
            log.bedTime = bedTime
            log.wakeTime = wakeTime
            log.quality = quality
            log.awakenings = awakenings
            log.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
            log.tags = parsedTags
        }
        try? context.save()
        Haptics.success(hapticsOn)
        dismiss()
    }
}
