import SwiftUI
import SwiftData

struct ReminderEditorView: View {
    let vehicle: Vehicle
    enum Mode { case create, edit(ServiceReminder) }
    let mode: Mode

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("axle.distanceUnit") private var distanceUnitRaw = DistanceUnit.km.rawValue

    @State private var title = ""
    @State private var type: ServiceType = .oilChange
    @State private var useDistance = true
    @State private var dueOdoText = ""
    @State private var repeatKmText = ""
    @State private var useDate = false
    @State private var dueDate = Calendar.current.date(byAdding: .month, value: 6, to: .now) ?? .now
    @State private var repeatMonths = 0

    private var distanceUnit: DistanceUnit { DistanceUnit(rawValue: distanceUnitRaw) ?? .km }
    private var isEditing: Bool { if case .edit = mode { return true } else { return false } }
    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty && (useDistance || useDate)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title (e.g. Oil change)", text: $title)
                    Picker("Type", selection: $type) {
                        ForEach(ServiceType.allCases) { Label($0.title, systemImage: $0.icon).tag($0) }
                    }
                }
                Section("Distance trigger") {
                    Toggle("Remind by distance", isOn: $useDistance.animation())
                    if useDistance {
                        HStack {
                            Text("Due at (\(distanceUnit.label))")
                            Spacer()
                            TextField("0", text: $dueOdoText).keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing).frame(width: 120)
                        }
                        HStack {
                            Text("Repeat every (\(distanceUnit.label))")
                            Spacer()
                            TextField("0 = no repeat", text: $repeatKmText).keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing).frame(width: 140)
                        }
                    }
                }
                Section("Date trigger") {
                    Toggle("Remind by date", isOn: $useDate.animation())
                    if useDate {
                        DatePicker("Due date", selection: $dueDate, displayedComponents: .date)
                        Picker("Repeat", selection: $repeatMonths) {
                            Text("No repeat").tag(0)
                            Text("Every 3 months").tag(3)
                            Text("Every 6 months").tag(6)
                            Text("Every 12 months").tag(12)
                        }
                    }
                }
                if case let .edit(r) = mode {
                    Section {
                        Button(role: .destructive) {
                            context.delete(r); try? context.save(); Haptics.warning(); dismiss()
                        } label: { Label("Delete reminder", systemImage: "trash") }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Reminder" : "New Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.disabled(!canSave) }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        switch mode {
        case .create:
            dueOdoText = String(format: "%.0f", distanceUnit.fromKm(vehicle.odometerKm + 10000))
            repeatKmText = String(format: "%.0f", distanceUnit.fromKm(10000))
        case .edit(let r):
            title = r.title; type = r.type
            useDistance = r.dueOdometerKm > 0
            dueOdoText = r.dueOdometerKm > 0 ? String(format: "%.0f", distanceUnit.fromKm(r.dueOdometerKm)) : ""
            repeatKmText = r.repeatEveryKm > 0 ? String(format: "%.0f", distanceUnit.fromKm(r.repeatEveryKm)) : ""
            useDate = r.dueDate != nil
            if let d = r.dueDate { dueDate = d }
            repeatMonths = r.repeatEveryMonths
        }
    }

    private func save() {
        let t = title.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        let dueOdoKm = useDistance ? distanceUnit.toKm(Double(dueOdoText.replacingOccurrences(of: ",", with: ".")) ?? 0) : 0
        let repeatKm = useDistance ? distanceUnit.toKm(Double(repeatKmText.replacingOccurrences(of: ",", with: ".")) ?? 0) : 0
        let dueDateValue = useDate ? dueDate : nil
        let repMonths = useDate ? repeatMonths : 0
        switch mode {
        case .create:
            let r = ServiceReminder(title: t, type: type, dueOdometerKm: dueOdoKm,
                                    dueDate: dueDateValue, repeatEveryKm: repeatKm,
                                    repeatEveryMonths: repMonths)
            r.vehicle = vehicle
            context.insert(r)
        case .edit(let r):
            r.title = t; r.type = type
            r.dueOdometerKm = dueOdoKm; r.repeatEveryKm = repeatKm
            r.dueDate = dueDateValue; r.repeatEveryMonths = repMonths
            r.isActive = true
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
