import SwiftUI
import SwiftData

/// Edit an existing session's project, tag and note; full delete supported from History.
struct SessionEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<Project> { !$0.isArchived }, sort: \Project.createdAt) private var projects: [Project]
    @Query private var settingsList: [AppSettings]

    @Bindable var session: FocusSession
    @State private var noteDraft: String = ""
    @State private var tagDraft: String = ""

    private var haptics: Bool { settingsList.first?.hapticsEnabled ?? true }

    var body: some View {
        NavigationStack {
            Form {
                Section("Session") {
                    LabeledContent("Focused", value: TimeFormat.durationSeconds(session.focusedSeconds))
                    LabeledContent("Mode", value: session.mode.label)
                    LabeledContent("Started", value: session.startedAt.formatted(date: .abbreviated, time: .shortened))
                    LabeledContent("Status", value: session.wasCompleted ? "Completed" : "Ended early")
                    Stepper(value: $session.distractionCount, in: 0...99) {
                        Text("Distractions: \(session.distractionCount)")
                    }
                }

                Section("Project") {
                    Picker("Project", selection: projectBinding) {
                        Text("Unassigned").tag(UUID?.none)
                        ForEach(projects) { p in
                            Text(p.name).tag(Optional(p.id))
                        }
                    }
                }

                Section("Tag") {
                    TextField("e.g. coding, writing", text: $tagDraft)
                        .textInputAutocapitalization(.never)
                }

                Section("Note") {
                    TextField("Optional note", text: $noteDraft, axis: .vertical)
                        .lineLimit(2...5)
                }
            }
            .navigationTitle("Edit Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                }
            }
            .onAppear {
                noteDraft = session.note
                tagDraft = session.tag
            }
        }
    }

    private var projectBinding: Binding<UUID?> {
        Binding(
            get: { session.project?.id },
            set: { newID in
                session.project = projects.first(where: { $0.id == newID })
            }
        )
    }

    private func save() {
        Haptics.success(haptics)
        session.note = noteDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        session.tag = tagDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        try? context.save()
        dismiss()
    }
}
