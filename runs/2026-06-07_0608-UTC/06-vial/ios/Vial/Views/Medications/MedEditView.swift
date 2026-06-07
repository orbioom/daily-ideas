import SwiftUI
import SwiftData

struct MedEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("vial.defaultThreshold") private var defaultThreshold = 7
    let existing: Medication?

    @State private var name = ""
    @State private var strength = ""
    @State private var form = "Tablet"
    @State private var colorHex: UInt32 = 0x5EB7F0
    @State private var unitsPerDose = 1.0
    @State private var doseTimes: [Int] = [480]
    @State private var everyDay = true
    @State private var weekdays: Set<Int> = []
    @State private var quantity = 0.0
    @State private var threshold = 7
    @State private var isActive = true
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    basicsCard
                    scheduleCard
                    daysCard
                    supplyCard
                    notesCard
                }
                .padding()
            }
            .navigationTitle(existing == nil ? "New Medication" : "Edit")
            .navigationBarTitleDisplayMode(.inline)
            .background(Brand.pageBackground)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || doseTimes.isEmpty)
                }
            }
            .onAppear(perform: load)
        }
    }

    private var basicsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Medication name", text: $name).font(.headline).foregroundStyle(Brand.text)
            Divider().overlay(Brand.hairline)
            TextField("Strength (e.g. 10 mg)", text: $strength).font(.subheadline).foregroundStyle(Brand.text2)
            Divider().overlay(Brand.hairline)
            HStack {
                Text("Form").foregroundStyle(Brand.text2); Spacer()
                Picker("Form", selection: $form) { ForEach(DoseEngine.forms, id: \.self) { Text($0).tag($0) } }.tint(Brand.text)
            }
            Divider().overlay(Brand.hairline)
            HStack {
                Text("Colour").foregroundStyle(Brand.text2); Spacer()
                ForEach(DoseEngine.colors, id: \.self) { c in
                    Circle().fill(Color(hex: c)).frame(width: 24, height: 24)
                        .overlay(Circle().strokeBorder(Brand.text, lineWidth: colorHex == c ? 2 : 0))
                        .onTapGesture { colorHex = c; Haptics.selection() }
                        .accessibilityLabel("Colour option")
                }
            }
        }
        .font(.subheadline).glassCard()
    }

    private var scheduleCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionTitle(text: "Dose times")
                Spacer()
                Button {
                    let next = (doseTimes.max() ?? 480) + 240
                    doseTimes.append(min(1410, next)); Haptics.tap()
                } label: { Image(systemName: "plus.circle") }.accessibilityLabel("Add time")
            }
            ForEach(Array(doseTimes.enumerated()), id: \.offset) { idx, _ in
                HStack {
                    DatePicker("", selection: timeBinding(idx), displayedComponents: .hourAndMinute)
                        .labelsHidden().tint(Brand.text)
                    Spacer()
                    if doseTimes.count > 1 {
                        Button(role: .destructive) {
                            doseTimes.remove(at: idx); Haptics.selection()
                        } label: { Image(systemName: "minus.circle").foregroundStyle(Brand.danger) }
                        .accessibilityLabel("Remove time")
                    }
                }
            }
            Divider().overlay(Brand.hairline)
            HStack {
                Text("Units per dose").foregroundStyle(Brand.text2)
                Spacer()
                Stepper("\(unitsPerDose == unitsPerDose.rounded() ? "\(Int(unitsPerDose))" : String(format: "%.1f", unitsPerDose))",
                        value: $unitsPerDose, in: 0.5...10, step: 0.5).fixedSize()
            }
            .font(.subheadline)
        }
        .glassCard()
    }

    private func timeBinding(_ idx: Int) -> Binding<Date> {
        Binding(
            get: { DoseEngine.minutesToTime(doseTimes[idx], on: Date()) },
            set: { newDate in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                doseTimes[idx] = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
            })
    }

    private var daysCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Every day", isOn: $everyDay).tint(Brand.live).foregroundStyle(Brand.text)
                .onChange(of: everyDay) { _, v in if v { weekdays.removeAll() } }
            if !everyDay {
                HStack(spacing: 6) {
                    ForEach(1...7, id: \.self) { d in
                        Button {
                            if weekdays.contains(d) { weekdays.remove(d) } else { weekdays.insert(d) }
                            Haptics.selection()
                        } label: {
                            Text(DoseEngine.weekdayNames[d].prefix(1))
                                .font(.caption.weight(.semibold))
                                .frame(width: 34, height: 34)
                                .foregroundStyle(weekdays.contains(d) ? .white : Brand.text2)
                                .background((weekdays.contains(d) ? AnyShapeStyle(Brand.inkGradient) : AnyShapeStyle(Brand.hairline.opacity(0.6))), in: Circle())
                        }
                        .accessibilityLabel(DoseEngine.weekdayNames[d])
                    }
                }
            }
        }
        .font(.subheadline).glassCard()
    }

    private var supplyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("On hand").foregroundStyle(Brand.text2)
                Spacer()
                TextField("0", value: $quantity, format: .number).keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing).font(Brand.mono(16)).foregroundStyle(Brand.text).frame(width: 80)
            }
            Divider().overlay(Brand.hairline)
            Stepper("Refill alert: \(threshold) days before run-out", value: $threshold, in: 1...60)
                .foregroundStyle(Brand.text2)
            Divider().overlay(Brand.hairline)
            Toggle("Active", isOn: $isActive).tint(Brand.live).foregroundStyle(Brand.text)
        }
        .font(.subheadline).glassCard()
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(text: "Notes")
            TextField("Instructions, prescriber…", text: $notes, axis: .vertical)
                .lineLimit(2...5).font(.subheadline).foregroundStyle(Brand.text)
        }.glassCard()
    }

    private func load() {
        guard let m = existing else { threshold = defaultThreshold; return }
        name = m.name; strength = m.strength; form = m.form; colorHex = m.colorHex
        unitsPerDose = m.unitsPerDose; doseTimes = m.sortedDoseTimes
        everyDay = m.weekdays.isEmpty; weekdays = Set(m.weekdays)
        quantity = m.quantityOnHand; threshold = m.refillThresholdDays
        isActive = m.isActive; notes = m.notes
    }

    private func save() {
        let t = name.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty, !doseTimes.isEmpty else { return }
        let m: Medication
        if let existing { m = existing } else { m = Medication(name: t); context.insert(m) }
        m.name = t; m.strength = strength; m.form = form; m.colorHex = colorHex
        m.unitsPerDose = max(0.5, unitsPerDose)
        m.doseTimes = doseTimes.sorted()
        m.weekdays = everyDay ? [] : Array(weekdays).sorted()
        m.quantityOnHand = max(0, quantity)
        m.refillThresholdDays = max(1, threshold)
        m.isActive = isActive; m.notes = notes
        try? context.save(); Haptics.success(); dismiss()
    }
}
