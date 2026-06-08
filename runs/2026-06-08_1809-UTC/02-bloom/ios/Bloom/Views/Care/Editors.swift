import SwiftUI
import SwiftData

struct WeightEditorView: View {
    let suggested: Double
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var date = Date()

    private var value: Double? {
        let v = Double(text.replacingOccurrences(of: ",", with: "."))
        guard let v, v > 0, v < 400 else { return nil }
        return v
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Weight (kg)") {
                    TextField(suggested > 0 ? String(format: "%.1f", suggested) : "kg", text: $text)
                        .keyboardType(.decimalPad)
                        .font(.title3)
                    DatePicker("Date", selection: $date, in: ...Date(), displayedComponents: .date)
                }
            }
            .navigationTitle("Log Weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let value else { return }
                        context.insert(WeightEntry(date: date, kg: value))
                        try? context.save(); Haptics.success(); dismiss()
                    }
                    .disabled(value == nil)
                }
            }
            .onAppear { if suggested > 0 { text = String(format: "%.1f", suggested) } }
        }
    }
}

struct SymptomEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var symptom: Symptom = .nausea
    @State private var severity = 1
    @State private var note = ""
    @State private var date = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Symptom", selection: $symptom) {
                        ForEach(Symptom.allCases) { s in
                            Label(s.title, systemImage: s.icon).tag(s)
                        }
                    }
                    Picker("Severity", selection: $severity) {
                        Text("Mild").tag(1); Text("Moderate").tag(2); Text("Strong").tag(3)
                    }
                    .pickerStyle(.segmented)
                    DatePicker("Date", selection: $date, in: ...Date(), displayedComponents: .date)
                }
                Section("Note") {
                    TextField("Optional note", text: $note, axis: .vertical).lineLimit(2...4)
                }
            }
            .navigationTitle("Log Symptom")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        context.insert(SymptomEntry(date: date, symptom: symptom, severity: severity, note: note))
                        try? context.save(); Haptics.success(); dismiss()
                    }
                }
            }
        }
    }
}

struct AppointmentEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var location = ""
    @State private var notes = ""
    @State private var date = Calendar.current.date(byAdding: .day, value: 7, to: .now) ?? .now

    private var canSave: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title (e.g. 20-week scan)", text: $title)
                    TextField("Location", text: $location)
                    DatePicker("When", selection: $date)
                }
                Section("Notes") {
                    TextField("Questions to ask, reminders…", text: $notes, axis: .vertical).lineLimit(2...5)
                }
            }
            .navigationTitle("Appointment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let t = title.trimmingCharacters(in: .whitespaces)
                        guard !t.isEmpty else { return }
                        context.insert(Appointment(date: date, title: t, location: location, notes: notes))
                        try? context.save(); Haptics.success(); dismiss()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }
}
