import SwiftUI
import SwiftData

struct EntryEditorView: View {
    @Bindable var entry: TimeEntry
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<Project> { !$0.archived }, sort: \Project.name) private var projects: [Project]

    @State private var isRunningToggle: Bool

    init(entry: TimeEntry) {
        self.entry = entry
        _isRunningToggle = State(initialValue: entry.isRunning)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Form {
                    Section {
                        TextField("Description", text: $entry.detail)
                        Picker("Project", selection: Binding(
                            get: { entry.project },
                            set: { entry.project = $0 }
                        )) {
                            Text("No project").tag(Optional<Project>.none)
                            ForEach(projects) { p in Text(p.name).tag(Optional(p)) }
                        }
                    }
                    Section("Time") {
                        DatePicker("Start", selection: $entry.start)
                        Toggle("Still running", isOn: $isRunningToggle)
                        if !isRunningToggle {
                            DatePicker("End", selection: Binding(
                                get: { entry.end ?? max(entry.start, Date()) },
                                set: { entry.end = $0 }
                            ), in: entry.start...)
                        }
                        LabeledContent("Duration", value: DurationFormat.compact(entry.seconds()))
                    }
                    Section {
                        Button(role: .destructive) {
                            context.delete(entry); Haptics.warning(); dismiss()
                        } label: {
                            Label("Delete entry", systemImage: "trash").frame(maxWidth: .infinity)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { save() }.fontWeight(.semibold)
                }
            }
            .onChange(of: isRunningToggle) { _, running in
                if running {
                    entry.end = nil
                } else if entry.end == nil {
                    entry.end = max(entry.start, Date())
                }
            }
        }
    }

    private func save() {
        if let end = entry.end, end < entry.start { entry.end = entry.start }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
