import SwiftUI
import SwiftData

struct RunEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("distanceUnit") private var unitRaw = DistanceUnit.km.rawValue
    let run: Run?

    @State private var name = ""
    @State private var date = Date.now
    @State private var distanceText = ""
    @State private var duration: Double = 0
    @State private var kind = RunKind.easy
    @State private var rpe = 5.0
    @State private var notes = ""

    private var unit: DistanceUnit { DistanceUnit(rawValue: unitRaw) ?? .km }
    private var distanceMeters: Double { (Double(distanceText) ?? 0) * unit.unitMeters }
    private var nameValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }
    private var valid: Bool { nameValid && distanceMeters > 0 && duration > 0 }
    private var livePace: String {
        guard distanceMeters > 0, duration > 0 else { return "—" }
        return unit.paceLabel(secPerKm: duration / (distanceMeters / 1000.0))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Run") {
                    TextField("Name (e.g. Saturday long run)", text: $name)
                    DatePicker("Date", selection: $date)
                    Picker("Type", selection: $kind) {
                        ForEach(RunKind.allCases) { Label($0.rawValue, systemImage: $0.icon).tag($0) }
                    }
                }
                Section("Distance & time") {
                    HStack {
                        Text("Distance")
                        Spacer()
                        TextField("0.0", text: $distanceText).keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing).font(Brand.mono(18)).frame(width: 90)
                        Text(unit.short).foregroundStyle(Brand.text3)
                    }
                    HStack {
                        Text("Duration")
                        Spacer()
                        DurationField(totalSeconds: $duration)
                    }
                    HStack {
                        Text("Pace").foregroundStyle(Brand.text2)
                        Spacer()
                        Text(livePace).font(Brand.mono(18, weight: .semibold)).foregroundStyle(Brand.magic)
                    }
                }
                Section("Effort (RPE \(Int(rpe)))") {
                    Slider(value: $rpe, in: 1...10, step: 1)
                }
                Section { TextField("Notes", text: $notes, axis: .vertical).lineLimit(2...4) }
            }
            .scrollContentBackground(.hidden).background(Brand.pageBackground)
            .navigationTitle(run == nil ? "Log Run" : "Edit Run")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.disabled(!valid) }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard let r = run else { return }
        name = r.name; date = r.date
        distanceText = String(format: "%.2f", unit.distance(meters: r.distanceMeters))
        duration = r.durationSeconds; kind = r.kind; rpe = Double(r.rpe); notes = r.notes
    }
    private func save() {
        if let r = run {
            r.name = name; r.date = date; r.distanceMeters = distanceMeters
            r.durationSeconds = duration; r.kind = kind; r.rpe = Int(rpe); r.notes = notes
        } else {
            context.insert(Run(name: name, date: date, distanceMeters: distanceMeters,
                               durationSeconds: duration, kind: kind, rpe: Int(rpe), notes: notes))
        }
        try? context.save(); Haptics.success(); dismiss()
    }
}
