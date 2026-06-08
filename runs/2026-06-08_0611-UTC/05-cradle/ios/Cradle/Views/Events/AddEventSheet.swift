import SwiftUI
import SwiftData

/// Full-featured add/edit sheet for any CareEvent kind. Used both for
/// quick-add from HomeView and for editing an existing event in TimelineLogView.
struct AddEventSheet: View {
    // If editing, pass the existing event. Otherwise pass defaultKind + baby.
    var existingEvent: CareEvent? = nil
    var defaultKind: EventKind = .feed
    var baby: Baby?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("cradle.unit") private var unitRaw = "ml"
    @AppStorage("cradle.clock24") private var use24h = false
    @AppStorage("cradle.defaultFeed") private var defaultFeedRaw = "breast"

    @State private var kind: EventKind = .feed
    @State private var startTime: Date = Date()
    @State private var endTime: Date = Date()
    @State private var hasEndTime = true
    @State private var feedType: FeedType = .breast
    @State private var amountText = ""
    @State private var breastSide: Side = .left
    @State private var diaperType: DiaperType = .wet
    @State private var note = ""
    @State private var validationError: String? = nil
    @State private var showSuccess = false

    private var isEditing: Bool { existingEvent != nil }
    private var useOz: Bool { unitRaw == "oz" }
    private var amountLabel: String { useOz ? "Amount (oz)" : "Amount (mL)" }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground

                ScrollView {
                    VStack(spacing: 20) {
                        // Kind selector (only when adding new)
                        if !isEditing {
                            kindPicker
                        }

                        // Time fields
                        timeSection

                        // Kind-specific fields
                        switch kind {
                        case .feed: feedSection
                        case .sleep: sleepSection
                        case .diaper: diaperSection
                        case .pump: pumpSection
                        case .note: EmptyView()
                        }

                        // Note
                        noteSection

                        // Validation error
                        if let err = validationError {
                            Text(err)
                                .font(.caption)
                                .foregroundStyle(Brand.danger)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 20)
                                .accessibilityLabel("Validation error: \(err)")
                        }

                        // Save button
                        Button(isEditing ? "Save Changes" : "Log \(kind.label)") {
                            save()
                        }
                        .buttonStyle(InkButtonStyle())
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle(isEditing ? "Edit \(kind.label)" : "Log \(kind.label)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        Haptics.tap()
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            prepopulate()
        }
    }

    // MARK: - Kind Picker

    @ViewBuilder
    private var kindPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(EventKind.allCases, id: \.self) { k in
                    Button {
                        Haptics.selection()
                        kind = k
                        resetKindFields()
                    } label: {
                        Label(k.label, systemImage: k.symbol)
                            .font(.subheadline.weight(kind == k ? .bold : .regular))
                            .foregroundStyle(kind == k ? k.color : Brand.text2)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(kind == k ? k.color.opacity(0.12) : Color.clear, in: Capsule())
                            .overlay(
                                Capsule().strokeBorder(
                                    kind == k ? k.color.opacity(0.45) : Brand.hairline,
                                    lineWidth: 1
                                )
                            )
                    }
                    .accessibilityAddTraits(kind == k ? .isSelected : [])
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Time Section

    @ViewBuilder
    private var timeSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Eyebrow(text: "Time")

                DatePicker(
                    "Start",
                    selection: $startTime,
                    in: ...Date(),
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.compact)
                .foregroundStyle(Brand.text)
                .accessibilityLabel("Start time")

                if kind != .diaper && kind != .note {
                    Toggle("Has end time", isOn: $hasEndTime)
                        .foregroundStyle(Brand.text)
                        .tint(kind.color)

                    if hasEndTime {
                        DatePicker(
                            "End",
                            selection: $endTime,
                            in: startTime...,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .datePickerStyle(.compact)
                        .foregroundStyle(Brand.text)
                        .accessibilityLabel("End time")
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Feed Section

    @ViewBuilder
    private var feedSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Eyebrow(text: "Feed details")

                Picker("Type", selection: $feedType) {
                    ForEach(FeedType.allCases, id: \.self) { t in
                        Label(t.label, systemImage: t.symbol).tag(t)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("Feed type")

                if feedType == .breast {
                    Picker("Side", selection: $breastSide) {
                        ForEach(Side.allCases, id: \.self) { s in
                            Text(s.label).tag(s)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityLabel("Breast side")
                }

                if feedType == .bottle || feedType == .solid {
                    HStack {
                        Text(amountLabel)
                            .foregroundStyle(Brand.text2)
                            .font(.subheadline)
                        Spacer()
                        TextField("0", text: $amountText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                            .foregroundStyle(Brand.text)
                            .accessibilityLabel(amountLabel)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Sleep Section

    @ViewBuilder
    private var sleepSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Eyebrow(text: "Sleep details")
                Text("Toggle 'Has end time' off to start a live timer.")
                    .font(.caption)
                    .foregroundStyle(Brand.text2)
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Diaper Section

    @ViewBuilder
    private var diaperSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Eyebrow(text: "Diaper details")

                Picker("Type", selection: $diaperType) {
                    ForEach(DiaperType.allCases, id: \.self) { t in
                        Label(t.label, systemImage: t.symbol).tag(t)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("Diaper type")
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Pump Section

    @ViewBuilder
    private var pumpSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Eyebrow(text: "Pump details")

                HStack {
                    Text(amountLabel)
                        .foregroundStyle(Brand.text2)
                        .font(.subheadline)
                    Spacer()
                    TextField("0", text: $amountText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .foregroundStyle(Brand.text)
                        .accessibilityLabel(amountLabel)
                }
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Note Section

    @ViewBuilder
    private var noteSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Eyebrow(text: "Note")

                TextField("Optional note…", text: $note, axis: .vertical)
                    .lineLimit(3...6)
                    .foregroundStyle(Brand.text)
                    .font(.body)
                    .accessibilityLabel("Note")
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Logic

    private func prepopulate() {
        if let event = existingEvent {
            kind = event.kind
            startTime = event.startTime
            if let et = event.endTime {
                endTime = et
                hasEndTime = true
            } else {
                endTime = Date()
                hasEndTime = false
            }
            feedType = event.feedType ?? FeedType(rawValue: defaultFeedRaw) ?? .breast
            if let ml = event.amountML {
                amountText = useOz
                    ? String(format: "%.1f", Format.mlToOz(ml))
                    : String(format: "%.0f", ml)
            }
            breastSide = event.breastSide ?? .left
            diaperType = event.diaperType ?? .wet
            note = event.note
        } else {
            kind = defaultKind
            feedType = FeedType(rawValue: defaultFeedRaw) ?? .breast
            startTime = Date()
            endTime = Date()
            // Diaper always instant
            if defaultKind == .diaper || defaultKind == .note {
                hasEndTime = true
            }
        }
    }

    private func resetKindFields() {
        amountText = ""
        feedType = FeedType(rawValue: defaultFeedRaw) ?? .breast
        breastSide = .left
        diaperType = .wet
        note = ""
        validationError = nil
        if kind == .diaper || kind == .note {
            hasEndTime = true
        }
    }

    private func save() {
        // Validation
        if kind == .feed && (feedType == .bottle || feedType == .solid) {
            if let txt = Double(amountText.replacingOccurrences(of: ",", with: ".")), txt < 0 {
                validationError = "Amount must be positive."
                Haptics.warning()
                return
            }
        }
        if hasEndTime && endTime < startTime {
            validationError = "End time must be after start time."
            Haptics.warning()
            return
        }

        let resolvedEnd: Date?
        if kind == .diaper {
            resolvedEnd = startTime
        } else if kind == .note {
            resolvedEnd = startTime
        } else if hasEndTime {
            resolvedEnd = endTime
        } else {
            resolvedEnd = nil
        }

        var amountML: Double? = nil
        let amountDouble = Double(amountText.replacingOccurrences(of: ",", with: "."))
        if let amt = amountDouble, amt > 0 {
            amountML = useOz ? Format.ozToMl(amt) : amt
        }

        if let event = existingEvent {
            // Update in place
            event.startTime = startTime
            event.endTime = resolvedEnd
            event.feedType = kind == .feed ? feedType : nil
            event.amountML = amountML
            event.breastSide = (kind == .feed && feedType == .breast) ? breastSide : nil
            event.diaperType = kind == .diaper ? diaperType : nil
            event.note = note
        } else {
            guard let babyRef = baby else {
                validationError = "No baby selected."
                Haptics.warning()
                return
            }
            let event = CareEvent(
                kind: kind,
                startTime: startTime,
                endTime: resolvedEnd,
                feedType: kind == .feed ? feedType : nil,
                amountML: amountML,
                breastSide: (kind == .feed && feedType == .breast) ? breastSide : nil,
                diaperType: kind == .diaper ? diaperType : nil,
                note: note,
                baby: babyRef
            )
            context.insert(event)
            babyRef.events.append(event)
        }

        Haptics.success()
        dismiss()
    }
}
