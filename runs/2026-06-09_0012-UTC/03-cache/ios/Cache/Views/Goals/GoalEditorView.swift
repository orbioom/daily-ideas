import SwiftUI
import SwiftData

struct GoalEditorView: View {
    var goal: Goal?
    var nextIndex: Int

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("cache.symbol") private var symbol = "$"

    @State private var name = ""
    @State private var targetText = ""
    @State private var hasDeadline = false
    @State private var targetDate = Calendar.current.date(byAdding: .month, value: 6, to: .now) ?? .now
    @State private var planText = ""
    @State private var goalSymbol: GoalSymbol = .star
    @State private var goalColor: GoalColor = .teal
    @State private var notes = ""
    @State private var loaded = false

    private var targetValue: Double? {
        let v = Double(targetText.replacingOccurrences(of: ",", with: ""))
        guard let v, v > 0 else { return nil }
        return v
    }
    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty && targetValue != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Goal") {
                    TextField("Name", text: $name)
                    HStack {
                        Text(symbol).foregroundStyle(Brand.text3)
                        TextField("Target amount", text: $targetText).keyboardType(.numberPad)
                    }
                }
                Section("Deadline") {
                    Toggle("Has a target date", isOn: $hasDeadline.animation())
                    if hasDeadline {
                        DatePicker("Target date", selection: $targetDate, in: Date()..., displayedComponents: .date)
                    }
                }
                Section("Monthly plan (optional)") {
                    HStack {
                        Text(symbol).foregroundStyle(Brand.text3)
                        TextField("How much you'll add per month", text: $planText).keyboardType(.numberPad)
                    }
                    Text("Used for projections when set. Otherwise Cache uses your real pace.")
                        .font(.caption).foregroundStyle(Brand.text3)
                }
                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 14) {
                        ForEach(GoalSymbol.allCases) { s in
                            Image(systemName: s.systemName)
                                .font(.title3)
                                .frame(width: 40, height: 40)
                                .foregroundStyle(goalSymbol == s ? .white : Brand.text2)
                                .background(goalSymbol == s ? goalColor.color : Color.clear, in: Circle())
                                .onTapGesture { Haptics.selection(); goalSymbol = s }
                                .accessibilityLabel(s.rawValue)
                                .accessibilityAddTraits(goalSymbol == s ? .isSelected : [])
                        }
                    }
                    .padding(.vertical, 4)
                }
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(GoalColor.allCases) { c in
                            Circle().fill(c.color).frame(height: 36)
                                .overlay(Circle().strokeBorder(Brand.text, lineWidth: goalColor == c ? 3 : 0))
                                .onTapGesture { Haptics.selection(); goalColor = c }
                                .accessibilityLabel(c.rawValue)
                                .accessibilityAddTraits(goalColor == c ? .isSelected : [])
                        }
                    }
                    .padding(.vertical, 4)
                }
                Section("Notes") {
                    TextField("Optional", text: $notes, axis: .vertical).lineLimit(1...4)
                }
            }
            .navigationTitle(goal == nil ? "New goal" : "Edit goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) { Button("Save") { save() }.disabled(!canSave) }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard let goal, !loaded else { return }
        loaded = true
        name = goal.name
        targetText = goal.targetAmount == goal.targetAmount.rounded() ?
            String(Int(goal.targetAmount)) : String(goal.targetAmount)
        if let d = goal.targetDate { hasDeadline = true; targetDate = d }
        if goal.monthlyPlan > 0 { planText = String(Int(goal.monthlyPlan)) }
        goalSymbol = goal.symbol; goalColor = goal.color; notes = goal.notes
    }

    private func save() {
        guard let target = targetValue else { return }
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let plan = Double(planText.replacingOccurrences(of: ",", with: "")) ?? 0
        if let goal {
            goal.name = trimmed; goal.targetAmount = target
            goal.targetDate = hasDeadline ? targetDate : nil
            goal.monthlyPlan = max(0, plan)
            goal.symbol = goalSymbol; goal.color = goalColor; goal.notes = notes
        } else {
            let new = Goal(name: trimmed, targetAmount: target,
                           targetDate: hasDeadline ? targetDate : nil,
                           monthlyPlan: max(0, plan), symbol: goalSymbol,
                           color: goalColor, notes: notes, sortIndex: nextIndex)
            context.insert(new)
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
