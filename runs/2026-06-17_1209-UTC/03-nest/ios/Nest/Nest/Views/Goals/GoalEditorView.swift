import SwiftUI
import SwiftData

/// Create a new goal or edit an existing one.
struct GoalEditorView: View {
    enum Mode {
        case create
        case edit(Goal)
    }

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var settings

    let mode: Mode

    @State private var name = ""
    @State private var category: GoalCategory = .other
    @State private var targetText = ""
    @State private var hasDeadline = true
    @State private var targetDate = Calendar.current.date(byAdding: .month, value: 12, to: .now) ?? .now
    @State private var priority = 2
    @State private var colorHex = Theme.goalSwatches[0]
    @State private var symbolName = "target"

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var parsedTarget: Double? {
        let cleaned = targetText.replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespaces)
        guard let value = Double(cleaned), value > 0 else { return nil }
        return value
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && parsedTarget != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. Emergency Fund", text: $name)
                        .font(Theme.rounded(16))
                }

                Section("Target") {
                    HStack {
                        Text(settings.currency.symbol)
                            .foregroundStyle(Theme.inkSoft)
                        TextField("0", text: $targetText)
                            .keyboardType(.decimalPad)
                            .font(Theme.money(17))
                    }
                    Toggle("Set a target date", isOn: $hasDeadline)
                    if hasDeadline {
                        DatePicker("By", selection: $targetDate, in: Date.now..., displayedComponents: .date)
                    }
                }

                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(GoalCategory.allCases) { c in
                            Label(c.title, systemImage: c.symbolName).tag(c)
                        }
                    }
                    .onChange(of: category) { _, newValue in
                        // Suggest a fitting symbol & color when the user hasn't customized.
                        symbolName = newValue.symbolName
                    }
                }

                Section("Priority") {
                    Picker("Priority", selection: $priority) {
                        Text("High").tag(1)
                        Text("Normal").tag(2)
                        Text("Low").tag(3)
                    }
                    .pickerStyle(.segmented)
                }

                Section("Color") {
                    swatchRow
                }
            }
            .navigationTitle(isEditing ? "Edit Goal" : "New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
            }
            .onAppear(perform: loadIfEditing)
        }
    }

    private var swatchRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Theme.goalSwatches, id: \.self) { hex in
                    Circle()
                        .fill(Color.fromGoalHex(hex))
                        .frame(width: 34, height: 34)
                        .overlay(
                            Circle()
                                .strokeBorder(Theme.ink, lineWidth: colorHex == hex ? 3 : 0)
                        )
                        .onTapGesture {
                            colorHex = hex
                            Haptics.select(settings.hapticsEnabled)
                        }
                        .accessibilityLabel("Color option")
                        .accessibilityAddTraits(colorHex == hex ? .isSelected : [])
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func loadIfEditing() {
        guard case let .edit(goal) = mode else {
            symbolName = category.symbolName
            return
        }
        name = goal.name
        category = goal.category
        targetText = String(format: "%.0f", goal.targetAmount)
        if let date = goal.targetDate {
            hasDeadline = true
            targetDate = date
        } else {
            hasDeadline = false
        }
        priority = goal.priority
        colorHex = goal.colorHex
        symbolName = goal.symbolName
    }

    private func save() {
        guard let target = parsedTarget else { return }
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let date: Date? = hasDeadline ? targetDate : nil

        switch mode {
        case .create:
            let goal = Goal(name: trimmedName,
                            symbolName: symbolName,
                            colorHex: colorHex,
                            targetAmount: target,
                            targetDate: date,
                            priority: priority,
                            category: category)
            context.insert(goal)
        case .edit(let goal):
            goal.name = trimmedName
            goal.symbolName = symbolName
            goal.colorHex = colorHex
            goal.targetAmount = target
            goal.targetDate = date
            goal.priority = priority
            goal.category = category
        }
        try? context.save()
        Haptics.success(settings.hapticsEnabled)
        dismiss()
    }
}
