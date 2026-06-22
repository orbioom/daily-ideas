import SwiftUI
import SwiftData

struct FoodLogEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let entry: FoodLogEntry?
    let prefillDate: Date

    @State private var foodName = ""
    @State private var mealType: MealType = .lunch
    @State private var portionSize: PortionSize = .medium
    @State private var date = Date()
    @State private var notes = ""
    @State private var tagInput = ""
    @State private var allergenTags: [String] = []
    @State private var showSuggestions = false

    private var suggestions: [String] {
        guard !foodName.isEmpty else { return [] }
        return FoodCatalog.suggestions(for: foodName).prefix(5).map { $0 }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Food") {
                    TextField("Food name", text: $foodName)
                        .onChange(of: foodName) { _, _ in showSuggestions = !foodName.isEmpty }
                    if showSuggestions && !suggestions.isEmpty {
                        ForEach(suggestions, id: \.self) { s in
                            Button(s) {
                                foodName = s
                                showSuggestions = false
                            }
                            .foregroundStyle(NourishTheme.sage)
                        }
                    }
                }
                Section("Meal Details") {
                    Picker("Meal Type", selection: $mealType) {
                        ForEach(MealType.allCases) { type in
                            Label(type.displayName, systemImage: type.icon).tag(type)
                        }
                    }
                    Picker("Portion", selection: $portionSize) {
                        ForEach(PortionSize.allCases) { p in Text(p.displayName).tag(p) }
                    }
                    DatePicker("Time", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }
                Section("Allergen Tags (optional)") {
                    HStack {
                        TextField("e.g. gluten, dairy", text: $tagInput)
                            .onSubmit { addTag() }
                        Button("Add") { addTag() }
                            .disabled(tagInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    if !allergenTags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(allergenTags, id: \.self) { tag in
                                    HStack(spacing: 4) {
                                        Text(tag)
                                            .font(.caption)
                                        Button { allergenTags.removeAll { $0 == tag } } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.caption)
                                        }
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(NourishTheme.terra.opacity(0.15), in: Capsule())
                                    .foregroundStyle(NourishTheme.terra)
                                }
                            }
                        }
                    }
                }
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 60)
                }
            }
            .navigationTitle(entry == nil ? "Log Food" : "Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(foodName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                if let e = entry {
                    foodName = e.foodName
                    mealType = MealType(rawValue: e.mealType) ?? .lunch
                    portionSize = PortionSize(rawValue: e.portionNote) ?? .medium
                    date = e.date
                    notes = e.notes
                    allergenTags = e.allergenTags
                } else {
                    date = prefillDate
                }
            }
        }
    }

    private func addTag() {
        let t = tagInput.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !t.isEmpty, !allergenTags.contains(t) else { return }
        allergenTags.append(t)
        tagInput = ""
    }

    private func save() {
        if let e = entry {
            e.foodName = foodName.trimmingCharacters(in: .whitespacesAndNewlines)
            e.mealType = mealType.rawValue
            e.portionNote = portionSize.rawValue
            e.date = date
            e.notes = notes
            e.allergenTags = allergenTags
        } else {
            let e = FoodLogEntry(
                foodName: foodName.trimmingCharacters(in: .whitespacesAndNewlines),
                mealType: mealType.rawValue,
                portionNote: portionSize.rawValue,
                notes: notes,
                allergenTags: allergenTags
            )
            e.date = date
            context.insert(e)
        }
        let gen = UIImpactFeedbackGenerator(style: .medium)
        gen.impactOccurred()
        dismiss()
    }
}
