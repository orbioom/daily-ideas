import SwiftUI
import SwiftData

struct TechniqueDetailView: View {
    @Bindable var technique: Technique
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var showEdit = false

    var body: some View {
        NavigationStack {
            List {
                Section("Details") {
                    row("Category", technique.category.rawValue)
                    row("Mastery", technique.mastery.label)
                    row("Practice Count", "\(technique.practiceCount)")
                    if let last = technique.lastPracticed {
                        row("Last Practiced", last.formatted(date: .abbreviated, time: .omitted))
                    }
                    Toggle("Favorite", isOn: $technique.isFavorite)
                        .onChange(of: technique.isFavorite) { _, _ in
                            try? context.save()
                        }
                }
                if !technique.details.isEmpty {
                    Section("Description") {
                        Text(technique.details)
                    }
                }
                Section("Track Practice") {
                    Button {
                        technique.practiceCount += 1
                        technique.lastPracticed = Date()
                        if technique.practiceCount >= 50 && technique.mastery.rawValue < MasteryLevel.mastered.rawValue {
                            technique.masteryRaw = min(MasteryLevel.mastered.rawValue, technique.masteryRaw + 1)
                        } else if technique.practiceCount >= 20 && technique.mastery == .developing {
                            technique.masteryRaw = MasteryLevel.competent.rawValue
                        } else if technique.practiceCount >= 8 && technique.mastery == .learning {
                            technique.masteryRaw = MasteryLevel.developing.rawValue
                        }
                        try? context.save()
                    } label: {
                        Label("Mark Practiced (+1)", systemImage: "plus.circle.fill")
                            .foregroundStyle(.red)
                    }

                    Picker("Update Mastery", selection: $technique.mastery) {
                        ForEach(MasteryLevel.allCases, id: \.self) { l in
                            Text(l.label).tag(l)
                        }
                    }
                    .onChange(of: technique.mastery) { _, _ in
                        try? context.save()
                    }
                }
            }
            .navigationTitle(technique.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit") { showEdit = true }
                }
            }
            .sheet(isPresented: $showEdit) {
                AddTechniqueView(editing: technique)
            }
        }
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).fontWeight(.medium)
        }
    }
}

struct AddTechniqueView: View {
    var editing: Technique? = nil
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var category = TechniqueCategory.punch
    @State private var details = ""
    @State private var mastery = MasteryLevel.learning
    @State private var showValidation = false

    private var isEditing: Bool { editing != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Technique") {
                    TextField("Name", text: $name)
                    Picker("Category", selection: $category) {
                        ForEach(TechniqueCategory.allCases, id: \.self) { c in
                            Label(c.rawValue, systemImage: c.icon).tag(c)
                        }
                    }
                    Picker("Mastery", selection: $mastery) {
                        ForEach(MasteryLevel.allCases, id: \.self) { l in
                            Text(l.label).tag(l)
                        }
                    }
                }
                Section("Description (optional)") {
                    TextField("Tips, cues, or notes", text: $details, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(isEditing ? "Edit Technique" : "Add Technique")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .alert("Check Input", isPresented: $showValidation) {
                Button("OK", role: .cancel) {}
            } message: { Text("Name is required.") }
        }
        .onAppear {
            if let t = editing {
                name = t.name; category = t.category; details = t.details; mastery = t.mastery
            }
        }
    }

    private func save() {
        let trimName = name.trimmingCharacters(in: .whitespaces)
        guard !trimName.isEmpty else { showValidation = true; return }
        if let t = editing {
            t.name = trimName; t.categoryRaw = category.rawValue
            t.details = details; t.masteryRaw = mastery.rawValue
        } else {
            let t = Technique(name: trimName, category: category, details: details,
                              mastery: mastery, isCustom: true)
            context.insert(t)
        }
        try? context.save()
        dismiss()
    }
}
