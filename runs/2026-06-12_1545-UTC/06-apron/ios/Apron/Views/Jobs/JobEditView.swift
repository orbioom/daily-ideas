import SwiftUI
import SwiftData

struct JobEditView: View {
    let job: Job?
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var role: JobRole = .server
    @State private var wage = ""
    @State private var isArchived = false
    @State private var showDelete = false

    private var isEditing: Bool { job != nil }
    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Job") {
                    TextField("Name (e.g. The Oyster Bar)", text: $name)
                    Picker("Role", selection: $role) {
                        ForEach(JobRole.allCases) { Label($0.rawValue, systemImage: $0.symbol).tag($0) }
                    }
                    HStack {
                        Text("Hourly wage")
                        Spacer()
                        Text(Currency.code).font(.caption).foregroundStyle(Theme.textSecondary)
                        TextField("0", text: $wage).keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing).frame(maxWidth: 90)
                    }
                }
                if isEditing {
                    Section {
                        Toggle("Archived", isOn: $isArchived).tint(Theme.accent)
                    } footer: {
                        Text("Archived jobs stay in your history but won't appear when logging new shifts.")
                    }
                    Section {
                        Button(role: .destructive) { showDelete = true } label: {
                            Label("Delete job & its shifts", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Job" : "New Job")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.disabled(!canSave) }
            }
            .onAppear(perform: load)
            .confirmationDialog("Delete this job and all its shifts?", isPresented: $showDelete, titleVisibility: .visible) {
                Button("Delete", role: .destructive) { deleteJob() }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private func load() {
        guard let j = job else { return }
        name = j.name; role = j.role
        wage = j.hourlyWage > 0 ? (j.hourlyWage.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(j.hourlyWage)) : String(format: "%.2f", j.hourlyWage)) : ""
        isArchived = j.isArchived
    }

    private func save() {
        let n = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !n.isEmpty else { return }
        let w = Double(wage.replacingOccurrences(of: ",", with: ".").filter { "0123456789.".contains($0) }) ?? 0
        let j = job ?? Job(name: n)
        j.name = n; j.role = role; j.hourlyWage = max(w, 0); j.isArchived = isArchived
        if job == nil { context.insert(j) }
        try? context.save()
        Haptics.success()
        dismiss()
    }

    private func deleteJob() {
        if let j = job { context.delete(j); try? context.save() }
        dismiss()
    }
}
