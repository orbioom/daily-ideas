import SwiftUI
import SwiftData

struct AddEditProjectView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let project: Project?
    let room: Room

    @State private var name = ""
    @State private var status: ProjectStatus = .planning
    @State private var category: ProjectCategory = .renovation
    @State private var budget = ""
    @State private var hasStart = false
    @State private var startDate = Date()
    @State private var hasTarget = false
    @State private var targetDate = Date()
    @State private var notes = ""

    var isEditing: Bool { project != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Project") {
                    TextField("Name (e.g. Kitchen Backsplash)", text: $name)
                        .accessibilityLabel("Project name")
                    Picker("Status", selection: $status) {
                        ForEach(ProjectStatus.allCases, id: \.self) { s in
                            Label(s.rawValue, systemImage: s.icon).tag(s)
                        }
                    }
                    .accessibilityLabel("Project status")
                    Picker("Category", selection: $category) {
                        ForEach(ProjectCategory.allCases, id: \.self) { c in
                            Text(c.rawValue).tag(c)
                        }
                    }
                    .accessibilityLabel("Project category")
                }
                Section("Budget") {
                    HStack {
                        Text("$")
                        TextField("0", text: $budget)
                            .keyboardType(.decimalPad)
                            .accessibilityLabel("Budget amount")
                    }
                }
                Section("Timeline") {
                    Toggle("Start Date", isOn: $hasStart)
                        .accessibilityLabel("Has start date")
                    if hasStart {
                        DatePicker("Start", selection: $startDate, displayedComponents: .date)
                            .accessibilityLabel("Start date")
                    }
                    Toggle("Target Completion", isOn: $hasTarget)
                        .accessibilityLabel("Has target completion date")
                    if hasTarget {
                        DatePicker("Target", selection: $targetDate, displayedComponents: .date)
                            .accessibilityLabel("Target completion date")
                    }
                }
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                        .accessibilityLabel("Project notes")
                }
            }
            .navigationTitle(isEditing ? "Edit Project" : "New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { populate() }
        }
    }

    private func populate() {
        guard let p = project else { return }
        name = p.name
        status = p.status
        category = p.category
        if p.budget > 0 { budget = String(format: "%.0f", p.budget) }
        if let s = p.startDate { startDate = s; hasStart = true }
        if let t = p.targetDate { targetDate = t; hasTarget = true }
        notes = p.notes
    }

    private func save() {
        let n = name.trimmingCharacters(in: .whitespaces)
        guard !n.isEmpty else { return }
        let budgetValue = Double(budget.replacingOccurrences(of: ",", with: ".")) ?? 0

        if let p = project {
            p.name = n; p.status = status; p.category = category
            p.budget = budgetValue
            p.startDate = hasStart ? startDate : nil
            p.targetDate = hasTarget ? targetDate : nil
            p.notes = notes
            if status == .complete && p.completedDate == nil { p.completedDate = Date() }
        } else {
            let p = Project(name: n, status: status, room: room)
            p.category = category; p.budget = budgetValue
            p.startDate = hasStart ? startDate : nil
            p.targetDate = hasTarget ? targetDate : nil
            p.notes = notes
            context.insert(p)
        }
        try? context.save()
        dismiss()
    }
}

struct AddRoomView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let property: Property

    @State private var name = ""
    @State private var type: RoomType = .other

    var body: some View {
        NavigationStack {
            Form {
                Section("Room") {
                    TextField("Name (e.g. Master Bath)", text: $name)
                        .accessibilityLabel("Room name")
                    Picker("Type", selection: $type) {
                        ForEach(RoomType.allCases, id: \.self) { t in
                            Label(t.rawValue, systemImage: t.icon).tag(t)
                        }
                    }
                    .accessibilityLabel("Room type")
                }
            }
            .navigationTitle("Add Room")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let n = name.trimmingCharacters(in: .whitespaces)
                        guard !n.isEmpty else { return }
                        let room = Room(name: n, type: type, property: property)
                        context.insert(room)
                        try? context.save()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

struct AddPropertyView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var address = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Property Name", text: $name)
                    .accessibilityLabel("Property name")
                TextField("Address", text: $address)
                    .accessibilityLabel("Address")
            }
            .navigationTitle("New Property")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let n = name.trimmingCharacters(in: .whitespaces)
                        guard !n.isEmpty else { return }
                        let prop = Property(name: n)
                        prop.address = address
                        context.insert(prop)
                        try? context.save()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
