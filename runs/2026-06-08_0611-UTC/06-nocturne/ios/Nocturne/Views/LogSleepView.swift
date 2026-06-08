import SwiftUI
import SwiftData

struct LogSleepView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss)      private var dismiss

    /// Pass an existing log to edit it; nil to create a new one.
    var existing: SleepLog? = nil

    @AppStorage("nocturne.defaultQuality") private var defaultQuality = 3
    @AppStorage("nocturne.clock24")         private var clock24       = false

    // Form state
    @State private var bedTime:    Date
    @State private var wakeTime:   Date
    @State private var quality:    Int
    @State private var awakenings: Int    = 0
    @State private var tags:       [String] = []
    @State private var note:       String = ""

    // Validation
    @State private var showValidationAlert = false
    @State private var validationMessage   = ""

    // Computed duration preview
    private var durationPreview: Double {
        let seconds = wakeTime.timeIntervalSince(bedTime)
        guard seconds > 0 else { return 0 }
        return seconds / 3600
    }

    private var isValid: Bool {
        wakeTime > bedTime && durationPreview <= 24
    }

    init(existing: SleepLog? = nil) {
        self.existing = existing
        let now = Date()
        let cal = Calendar.current
        // Default bed time: 11pm last night
        let defaultBed = cal.date(byAdding: .hour, value: -8, to: now) ?? now
        if let log = existing {
            _bedTime    = State(initialValue: log.bedTime)
            _wakeTime   = State(initialValue: log.wakeTime)
            _quality    = State(initialValue: log.quality)
            _awakenings = State(initialValue: log.awakenings)
            _tags       = State(initialValue: log.tags)
            _note       = State(initialValue: log.note)
        } else {
            _bedTime    = State(initialValue: defaultBed)
            _wakeTime   = State(initialValue: now)
            _quality    = State(initialValue: 3) // will be overridden in .onAppear
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground

                ScrollView {
                    VStack(spacing: 16) {
                        // Duration preview card
                        durationPreviewCard

                        // Times card
                        GlassCard {
                            VStack(alignment: .leading, spacing: 16) {
                                Eyebrow(text: "Sleep Times")

                                DatePicker(
                                    "Bed Time",
                                    selection: $bedTime,
                                    displayedComponents: [.date, .hourAndMinute]
                                )
                                .foregroundStyle(Brand.text)
                                .accessibilityLabel("Bed time")

                                Divider().overlay(Brand.hairline)

                                DatePicker(
                                    "Wake Time",
                                    selection: $wakeTime,
                                    displayedComponents: [.date, .hourAndMinute]
                                )
                                .foregroundStyle(Brand.text)
                                .accessibilityLabel("Wake time")
                            }
                        }
                        .padding(.horizontal, 20)

                        // Quality card
                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Eyebrow(text: "Quality")
                                StarRating(rating: $quality, interactive: true, starSize: 32)
                                Text(Format.qualityLabel(quality))
                                    .font(.subheadline)
                                    .foregroundStyle(Brand.text2)
                            }
                        }
                        .padding(.horizontal, 20)

                        // Awakenings card
                        GlassCard {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Eyebrow(text: "Awakenings")
                                    Text("\(awakenings)")
                                        .font(Brand.mono(28, weight: .semibold))
                                        .foregroundStyle(Brand.text)
                                }
                                Spacer()
                                Stepper("", value: $awakenings, in: 0...20)
                                    .labelsHidden()
                                    .onChange(of: awakenings) { _, _ in Haptics.selection() }
                                    .accessibilityLabel("Awakenings: \(awakenings)")
                                    .accessibilityHint("Adjust number of times you woke up")
                            }
                        }
                        .padding(.horizontal, 20)

                        // Tags card
                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Eyebrow(text: "Factors")
                                TagChips(selected: $tags)
                            }
                        }
                        .padding(.horizontal, 20)

                        // Note card
                        GlassCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Eyebrow(text: "Note")
                                TextField("Optional note about this night…", text: $note, axis: .vertical)
                                    .font(.body)
                                    .foregroundStyle(Brand.text)
                                    .lineLimit(3...6)
                                    .accessibilityLabel("Note")
                                    .accessibilityHint("Optional journal note for this night")
                            }
                        }
                        .padding(.horizontal, 20)

                        // Save button
                        Button(existing == nil ? "Save Sleep Log" : "Update Sleep Log") {
                            save()
                        }
                        .buttonStyle(InkButtonStyle())
                        .disabled(!isValid)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle(existing == nil ? "Log Sleep" : "Edit Sleep")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        Haptics.tap()
                        dismiss()
                    }
                    .foregroundStyle(Brand.text2)
                }
            }
            .alert("Check Your Times", isPresented: $showValidationAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(validationMessage)
            }
        }
        .onAppear {
            if existing == nil {
                quality = defaultQuality
            }
        }
    }

    // MARK: - Duration Preview Card

    private var durationPreviewCard: some View {
        GlassCard {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Eyebrow(text: "Duration Preview")
                    Text(durationPreview > 0 ? Format.duration(durationPreview) : "–")
                        .font(Brand.mono(30, weight: .bold))
                        .foregroundStyle(durationPreview > 0 ? Brand.text : Brand.text3)
                        .contentTransition(.numericText())
                        .animation(Brand.ease(0.3), value: durationPreview)

                    if durationPreview > 0 {
                        Text(durationPreviewLabel)
                            .font(.caption)
                            .foregroundStyle(Brand.text3)
                    }
                }
                Spacer()

                if !isValid && (wakeTime <= bedTime) {
                    VStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(Brand.warn)
                            .font(.title2)
                            .accessibilityHidden(true)
                        Text("Wake must\nbe after bed")
                            .font(.caption2)
                            .foregroundStyle(Brand.warn)
                            .multilineTextAlignment(.center)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Duration preview: \(durationPreview > 0 ? Format.duration(durationPreview) : "invalid times")")
    }

    private var durationPreviewLabel: String {
        if durationPreview > 24 { return "Over 24h — check times" }
        if durationPreview < 2  { return "Very short night" }
        return "\(Format.clock(bedTime, use24h: clock24)) → \(Format.clock(wakeTime, use24h: clock24))"
    }

    // MARK: - Save

    private func save() {
        guard wakeTime > bedTime else {
            validationMessage = "Wake time must be after bed time."
            showValidationAlert = true
            Haptics.warning()
            return
        }
        guard durationPreview <= 24 else {
            validationMessage = "Duration exceeds 24 hours. Please check your times."
            showValidationAlert = true
            Haptics.warning()
            return
        }

        if let log = existing {
            log.bedTime    = bedTime
            log.wakeTime   = wakeTime
            log.quality    = quality
            log.awakenings = awakenings
            log.tags       = tags
            log.note       = note
        } else {
            let log = SleepLog(
                bedTime:    bedTime,
                wakeTime:   wakeTime,
                quality:    quality,
                awakenings: awakenings,
                tags:       tags,
                note:       note
            )
            context.insert(log)
        }

        try? context.save()
        Haptics.success()
        dismiss()
    }
}
