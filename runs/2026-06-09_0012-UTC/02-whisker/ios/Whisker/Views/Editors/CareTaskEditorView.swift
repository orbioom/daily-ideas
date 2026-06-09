import SwiftUI
import SwiftData

struct CareTaskEditorView: View {
    let pet: Pet
    var task: CareTask?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var kind: CareKind = .feeding
    @State private var interval = 1
    @State private var hasLastDone = false
    @State private var lastDone = Date()
    @State private var isActive = true
    @State private var loaded = false

    private var canSave: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty && interval >= 1 }

    var body: some View {
        NavigationStack {
            Form {
                Section("Task") {
                    TextField("Title", text: $title)
                    Picker("Type", selection: $kind) {
                        ForEach(CareKind.allCases) { Label($0.title, systemImage: $0.icon).tag($0) }
                    }
                    .onChange(of: kind) { _, new in
                        if title.isEmpty || CareKind.allCases.map(\.title).contains(title) {
                            title = new.title
                        }
                        if task == nil { interval = new.defaultInterval }
                    }
                }
                Section("Repeat") {
                    Stepper(value: $interval, in: 1...730) {
                        Text("Every \(interval) day\(interval == 1 ? "" : "s")").font(Brand.mono(15))
                    }
                    Toggle("Active", isOn: $isActive)
                }
                Section("Last done") {
                    Toggle("Record a last-done date", isOn: $hasLastDone.animation())
                    if hasLastDone {
                        DatePicker("Last done", selection: $lastDone, in: ...Date(), displayedComponents: .date)
                    } else {
                        Text("Leave off and it will be due today.")
                            .font(.caption).foregroundStyle(Brand.text3)
                    }
                }
                if let task {
                    Section {
                        Button(role: .destructive) {
                            context.delete(task); try? context.save(); dismiss()
                        } label: { Text("Delete task") }
                    }
                }
            }
            .navigationTitle(task == nil ? "New task" : "Edit task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) { Button("Save") { save() }.disabled(!canSave) }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard !loaded else { return }
        loaded = true
        if let task {
            title = task.title; kind = task.kind; interval = task.intervalDays; isActive = task.isActive
            if let d = task.lastDone { hasLastDone = true; lastDone = d }
        } else {
            title = kind.title; interval = kind.defaultInterval
        }
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        if let task {
            task.title = trimmed; task.kind = kind; task.intervalDays = max(1, interval)
            task.isActive = isActive; task.lastDone = hasLastDone ? lastDone : nil
        } else {
            let new = CareTask(title: trimmed, kind: kind, intervalDays: max(1, interval),
                               lastDone: hasLastDone ? lastDone : nil)
            new.isActive = isActive
            new.pet = pet
            context.insert(new)
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
