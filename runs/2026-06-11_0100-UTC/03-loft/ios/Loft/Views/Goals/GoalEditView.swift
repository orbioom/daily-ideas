import SwiftUI
import SwiftData

struct GoalEditView: View {
    let goal: Goal?
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var category: BoardCategory = .personal
    @State private var hasDate = false
    @State private var targetDate = Date().addingTimeInterval(90 * 86400)
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Goal") {
                    TextField("What do you want to achieve?", text: $title, axis: .vertical)
                        .lineLimit(2...4)
                        .accessibilityLabel("Goal title")
                    Picker("Category", selection: $category) {
                        ForEach(BoardCategory.allCases, id: \.self) { cat in
                            Label(cat.rawValue, systemImage: cat.icon).tag(cat)
                        }
                    }
                }
                Section("Target Date") {
                    Toggle("Set a target date", isOn: $hasDate)
                    if hasDate {
                        DatePicker("Target Date", selection: $targetDate, displayedComponents: .date)
                    }
                }
                Section("Notes") {
                    TextField("Any notes, context, or motivation…", text: $notes, axis: .vertical)
                        .lineLimit(3...8)
                }
            }
            .navigationTitle(goal == nil ? "New Goal" : "Edit Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let g = goal {
                    title = g.title
                    category = g.category
                    hasDate = g.targetDate != nil
                    targetDate = g.targetDate ?? Date().addingTimeInterval(90 * 86400)
                    notes = g.notes
                }
            }
        }
    }

    private func save() {
        let t = title.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }

        if let g = goal {
            g.title = t
            g.categoryRaw = category.rawValue
            g.targetDate = hasDate ? targetDate : nil
            g.notes = notes
        } else {
            let g = Goal(title: t, category: category,
                         targetDate: hasDate ? targetDate : nil, notes: notes)
            modelContext.insert(g)
        }
        dismiss()
    }
}
