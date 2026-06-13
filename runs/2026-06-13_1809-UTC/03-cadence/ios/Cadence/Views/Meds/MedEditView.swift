import SwiftUI
import SwiftData

struct MedEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("remindersEnabled") private var remindersEnabled = false
    @Query private var allMeds: [Medication]

    let med: Medication?

    @State private var name: String
    @State private var form: MedForm
    @State private var strength: String
    @State private var colorHex: Int
    @State private var notes: String
    @State private var schedule: ScheduleKind
    @State private var dayMask: Int
    @State private var times: [Date]
    @State private var dosesPerTime: Int
    @State private var trackSupply: Bool
    @State private var supplyText: String
    @State private var refillText: String

    private let dayNames = ["S", "M", "T", "W", "T", "F", "S"]

    init(med: Medication?) {
        self.med = med
        _name = State(initialValue: med?.name ?? "")
        _form = State(initialValue: med?.form ?? .tablet)
        _strength = State(initialValue: med?.strength ?? "")
        _colorHex = State(initialValue: med?.colorHex ?? Int(Theme.pillColors[0].light))
        _notes = State(initialValue: med?.notes ?? "")
        _schedule = State(initialValue: med?.schedule ?? .everyDay)
        _dayMask = State(initialValue: med?.dayMask ?? 0b1111111)
        let mins = med?.times ?? [8 * 60]
        _times = State(initialValue: mins.map { Self.dateFrom(minute: $0) })
        _dosesPerTime = State(initialValue: med?.dosesPerTime ?? 1)
        _trackSupply = State(initialValue: med?.trackSupply ?? false)
        _supplyText = State(initialValue: med.map { String(Int($0.supplyCount)) } ?? "30")
        let defaultRefill = UserDefaults.standard.object(forKey: "defaultRefillThreshold") as? Int ?? 7
        _refillText = State(initialValue: med.map { String(Int($0.refillThreshold)) } ?? String(defaultRefill))
    }

    private var isValid: Bool {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        if schedule == .daysOfWeek && dayMask == 0 { return false }
        if schedule != .asNeeded && times.isEmpty { return false }
        return true
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                Form {
                    Section("Medication") {
                        TextField("Name (e.g. Vitamin D, Metformin)", text: $name)
                        Picker("Form", selection: $form) {
                            ForEach(MedForm.allCases) { f in Label(f.label, systemImage: f.icon).tag(f) }
                        }
                        TextField("Strength (e.g. 500 mg) — optional", text: $strength)
                    }

                    Section("Color") { colorPicker }

                    Section("Schedule") {
                        Picker("Repeat", selection: $schedule) {
                            ForEach(ScheduleKind.allCases) { Text($0.label).tag($0) }
                        }
                        if schedule == .daysOfWeek { dayToggles }
                        if schedule != .asNeeded {
                            timesEditor
                            Stepper("\(dosesPerTime) \(form.label.lowercased()) per dose", value: $dosesPerTime, in: 1...20)
                        } else {
                            Text("Logged only when you take it — no fixed times.")
                                .font(Theme.rounded(13, .regular)).foregroundStyle(Theme.inkSoft)
                        }
                    }

                    Section("Supply") {
                        Toggle("Track how much I have", isOn: $trackSupply)
                        if trackSupply {
                            HStack {
                                Text("On hand"); Spacer()
                                TextField("0", text: $supplyText).keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing).frame(maxWidth: 90)
                                Text(form.label.lowercased() + "s").foregroundStyle(Theme.inkSoft)
                            }
                            HStack {
                                Text("Warn me at"); Spacer()
                                TextField("0", text: $refillText).keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing).frame(maxWidth: 90)
                                Text("left").foregroundStyle(Theme.inkSoft)
                            }
                        }
                    }

                    Section("Notes") {
                        TextField("e.g. take with food", text: $notes, axis: .vertical).lineLimit(1...3)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(med == nil ? "Add medication" : "Edit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.disabled(!isValid).bold() }
            }
        }
    }

    private var colorPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Theme.pillColors, id: \.light) { c in
                    let selected = colorHex == Int(c.light)
                    Circle()
                        .fill(Color.dyn(c.light, c.dark))
                        .frame(width: 34, height: 34)
                        .overlay(Circle().stroke(Theme.ink, lineWidth: selected ? 3 : 0).padding(-3))
                        .overlay(selected ? Image(systemName: "checkmark").font(.system(size: 13, weight: .bold)).foregroundStyle(.white) : nil)
                        .onTapGesture { colorHex = Int(c.light); Haptics.tap() }
                        .accessibilityLabel(c.name)
                        .accessibilityAddTraits(selected ? .isSelected : [])
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var dayToggles: some View {
        HStack(spacing: 8) {
            ForEach(0..<7, id: \.self) { i in
                let on = (dayMask & (1 << i)) != 0
                Button {
                    dayMask ^= (1 << i); Haptics.tap()
                } label: {
                    Text(dayNames[i])
                        .font(Theme.rounded(14, .bold))
                        .frame(width: 38, height: 38)
                        .background(on ? Theme.accent : Theme.surfaceAlt, in: Circle())
                        .foregroundStyle(on ? .white : Theme.inkSoft)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"][i])
                .accessibilityValue(on ? "on" : "off")
            }
        }
    }

    private var timesEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(times.indices, id: \.self) { i in
                HStack {
                    DatePicker("", selection: Binding(
                        get: { times[i] },
                        set: { times[i] = $0 }), displayedComponents: .hourAndMinute)
                        .labelsHidden()
                    Spacer()
                    if times.count > 1 {
                        Button {
                            times.remove(at: i)
                        } label: { Image(systemName: "minus.circle.fill").foregroundStyle(Theme.bad) }
                        .accessibilityLabel("Remove time")
                    }
                }
            }
            Button {
                times.append(Self.dateFrom(minute: 12 * 60)); Haptics.tap()
            } label: {
                Label("Add time", systemImage: "plus.circle.fill").foregroundStyle(Theme.accent)
            }
        }
    }

    private func save() {
        guard isValid else { return }
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let minutes = times.map { Self.minuteFrom(date: $0) }.sorted()
        let supply = Double(supplyText) ?? 0
        let refill = Double(refillText) ?? 0

        if let med {
            med.name = trimmed; med.form = form; med.strength = strength
            med.colorHex = colorHex; med.notes = notes
            med.schedule = schedule; med.dayMask = dayMask
            med.times = minutes; med.dosesPerTime = dosesPerTime
            med.trackSupply = trackSupply; med.supplyCount = supply; med.refillThreshold = refill
        } else {
            let m = Medication(name: trimmed, form: form, strength: strength, colorHex: colorHex,
                               schedule: schedule, dayMask: dayMask, times: minutes,
                               dosesPerTime: dosesPerTime, supplyCount: supply,
                               refillThreshold: refill, trackSupply: trackSupply, notes: notes)
            context.insert(m)
        }
        try? context.save()
        Haptics.success()
        let snapshot = (try? context.fetch(FetchDescriptor<Medication>())) ?? allMeds
        let enabled = remindersEnabled
        Task { await NotificationScheduler.reschedule(meds: snapshot, enabled: enabled) }
        dismiss()
    }

    private static func dateFrom(minute: Int) -> Date {
        var c = DateComponents(); c.hour = minute / 60; c.minute = minute % 60
        return Calendar.current.date(from: c) ?? Date()
    }
    private static func minuteFrom(date: Date) -> Int {
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }
}
