import SwiftUI
import SwiftData

struct SymptomEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let entry: SymptomEntry?

    @State private var symptomName = ""
    @State private var severity = 3
    @State private var date = Date()
    @State private var notes = ""
    @State private var showSuggestions = false

    private var suggestions: [String] {
        SymptomLibrary.suggestions(for: symptomName).prefix(6).map { $0 }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Symptom") {
                    TextField("e.g. bloating, headache", text: $symptomName)
                        .onChange(of: symptomName) { _, _ in showSuggestions = !symptomName.isEmpty }
                    if showSuggestions && !suggestions.isEmpty {
                        ForEach(suggestions, id: \.self) { s in
                            Button(s) {
                                symptomName = s
                                showSuggestions = false
                            }
                            .foregroundStyle(NourishTheme.terra)
                        }
                    }
                }
                Section("Severity") {
                    VStack(spacing: 12) {
                        HStack(spacing: 8) {
                            ForEach(1...5, id: \.self) { level in
                                Button {
                                    severity = level
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                } label: {
                                    Circle()
                                        .fill(level <= severity ? NourishTheme.terra : Color.gray.opacity(0.2))
                                        .frame(width: 36, height: 36)
                                        .overlay {
                                            Text("\(level)")
                                                .font(.caption.weight(.bold))
                                                .foregroundStyle(level <= severity ? .white : NourishTheme.secondaryText)
                                        }
                                }
                            }
                        }
                        Text(["Very Mild","Mild","Moderate","Severe","Very Severe"][severity - 1])
                            .font(.caption)
                            .foregroundStyle(NourishTheme.secondaryText)
                    }
                    .frame(maxWidth: .infinity)
                }
                Section {
                    DatePicker("Time", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }
                Section("Notes") {
                    TextEditor(text: $notes).frame(minHeight: 60)
                }
            }
            .navigationTitle(entry == nil ? "Log Symptom" : "Edit Symptom")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(symptomName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                if let e = entry {
                    symptomName = e.symptomName
                    severity = e.severity
                    date = e.date
                    notes = e.notes
                }
            }
        }
    }

    private func save() {
        if let e = entry {
            e.symptomName = symptomName.trimmingCharacters(in: .whitespacesAndNewlines)
            e.severity = severity
            e.date = date
            e.notes = notes
        } else {
            let e = SymptomEntry(
                symptomName: symptomName.trimmingCharacters(in: .whitespacesAndNewlines),
                severity: severity,
                notes: notes
            )
            e.date = date
            context.insert(e)
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        dismiss()
    }
}
