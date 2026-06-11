import SwiftUI
import SwiftData

struct ApplicationDetailView: View {
    @Bindable var application: Application
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss

    @State private var showEdit = false
    @State private var showStagePicker = false
    @State private var showAddInterview = false
    @State private var showAddContact = false
    @State private var showAddFollowUp = false
    @State private var confirmDelete = false

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                header
                stageCard
                followUpsCard
                interviewsCard
                contactsCard
                historyCard
                if !application.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Notes").font(.headline)
                        Text(application.notes)
                            .font(.subheadline)
                            .foregroundStyle(Theme.inkSoft(scheme))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .hiredCard()
                }
                Button(role: .destructive) {
                    confirmDelete = true
                } label: {
                    Label("Delete application", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
            .padding()
        }
        .background(Theme.background(scheme))
        .navigationTitle(application.company)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { showEdit = true }
            }
        }
        .sheet(isPresented: $showEdit) {
            ApplicationEditorView(application: application)
        }
        .sheet(isPresented: $showAddInterview) {
            InterviewEditorSheet(application: application)
        }
        .sheet(isPresented: $showAddContact) {
            ContactEditorSheet(application: application)
        }
        .sheet(isPresented: $showAddFollowUp) {
            FollowUpEditorSheet(application: application)
        }
        .confirmationDialog("Move to which stage?", isPresented: $showStagePicker, titleVisibility: .visible) {
            ForEach(Stage.allCases.filter { $0 != application.stage }) { s in
                Button(s.label) { move(to: s) }
            }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog("Delete \(application.company)?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                context.delete(application)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func move(to stage: Stage) {
        application.stageRaw = stage.rawValue
        if stage == .applied && application.appliedDate == nil {
            application.appliedDate = Date()
        }
        let event = StageEvent(stage: stage)
        event.application = application
        context.insert(event)
        Haptics.success()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(application.role)
                .font(Theme.display(24))
                .foregroundStyle(Theme.ink(scheme))
            HStack(spacing: 10) {
                if !application.location.isEmpty {
                    Label(application.location, systemImage: "mappin")
                }
                Label(application.workMode.label, systemImage: "building.2")
                if !application.salaryText.isEmpty {
                    Label(application.salaryText, systemImage: "dollarsign.circle")
                }
            }
            .font(.caption)
            .foregroundStyle(Theme.inkSoft(scheme))
            if !application.link.isEmpty, let url = URL(string: application.link) {
                Link(destination: url) {
                    Label("Job posting", systemImage: "arrow.up.right.square")
                        .font(.caption.weight(.semibold))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .hiredCard()
    }

    private var stageCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("Current stage")
                    .font(.caption)
                    .foregroundStyle(Theme.inkSoft(scheme))
                StageChip(stage: application.stage)
            }
            Spacer()
            Button {
                showStagePicker = true
            } label: {
                Label("Move", systemImage: "arrow.right.circle.fill")
                    .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.blue)
        }
        .hiredCard()
    }

    private var followUpsCard: some View {
        let pending = application.followUps.sorted { $0.dueDate < $1.dueDate }
        return sectionCard(title: "Follow-ups", addAction: { showAddFollowUp = true }) {
            if pending.isEmpty {
                Text("No follow-ups. Add one so this thread never goes cold.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSoft(scheme))
            } else {
                ForEach(pending) { task in
                    HStack {
                        Button {
                            task.isDone.toggle()
                            Haptics.tap()
                        } label: {
                            Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(task.isDone ? Theme.blue : Theme.inkSoft(scheme))
                                .font(.title3)
                        }
                        .accessibilityLabel(task.isDone ? "Mark \(task.title) not done" : "Mark \(task.title) done")
                        VStack(alignment: .leading, spacing: 2) {
                            Text(task.title)
                                .font(.subheadline)
                                .strikethrough(task.isDone)
                            Text(task.dueDate.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption2)
                                .foregroundStyle(!task.isDone && task.dueDate < Calendar.current.startOfDay(for: Date())
                                                 ? .red : Theme.inkSoft(scheme))
                        }
                        Spacer()
                        Button(role: .destructive) {
                            context.delete(task)
                        } label: {
                            Image(systemName: "trash")
                                .font(.caption)
                        }
                        .accessibilityLabel("Delete follow-up \(task.title)")
                    }
                }
            }
        }
    }

    private var interviewsCard: some View {
        let sorted = application.interviews.sorted { $0.scheduledAt < $1.scheduledAt }
        return sectionCard(title: "Interviews", addAction: { showAddInterview = true }) {
            if sorted.isEmpty {
                Text("No interviews scheduled yet.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSoft(scheme))
            } else {
                ForEach(sorted) { interview in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(interview.kind.label)
                                .font(.subheadline.weight(.semibold))
                            Text(interview.scheduledAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(Theme.inkSoft(scheme))
                            if !interview.notes.isEmpty {
                                Text(interview.notes)
                                    .font(.caption)
                                    .foregroundStyle(Theme.inkSoft(scheme))
                            }
                        }
                        Spacer()
                        Menu {
                            ForEach(InterviewOutcome.allCases, id: \.self) { outcome in
                                Button(outcome.label) { interview.outcomeRaw = outcome.rawValue }
                            }
                            Divider()
                            Button("Delete", role: .destructive) { context.delete(interview) }
                        } label: {
                            Text(interview.outcome.label)
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(outcomeColor(interview.outcome).opacity(0.15), in: Capsule())
                                .foregroundStyle(outcomeColor(interview.outcome))
                        }
                        .accessibilityLabel("Interview outcome: \(interview.outcome.label). Tap to change.")
                    }
                }
            }
        }
    }

    private func outcomeColor(_ outcome: InterviewOutcome) -> Color {
        switch outcome {
        case .pending: return Theme.inkSoft(scheme)
        case .passed: return .green
        case .failed: return .red
        }
    }

    private var contactsCard: some View {
        sectionCard(title: "People", addAction: { showAddContact = true }) {
            if application.contacts.isEmpty {
                Text("Recruiters and interviewers you meet along the way.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSoft(scheme))
            } else {
                ForEach(application.contacts.sorted { $0.name < $1.name }) { person in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(person.name).font(.subheadline.weight(.semibold))
                            if !person.title.isEmpty {
                                Text(person.title)
                                    .font(.caption)
                                    .foregroundStyle(Theme.inkSoft(scheme))
                            }
                            if !person.email.isEmpty {
                                Text(person.email)
                                    .font(.caption)
                                    .foregroundStyle(Theme.blue)
                                    .textSelection(.enabled)
                            }
                        }
                        Spacer()
                        Button(role: .destructive) {
                            context.delete(person)
                        } label: {
                            Image(systemName: "trash").font(.caption)
                        }
                        .accessibilityLabel("Delete contact \(person.name)")
                    }
                }
            }
        }
    }

    private var historyCard: some View {
        let events = application.events.sorted { $0.date > $1.date }
        return VStack(alignment: .leading, spacing: 10) {
            Text("History").font(.headline)
            if events.isEmpty {
                Text("Stage changes will appear here.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSoft(scheme))
            } else {
                ForEach(events) { event in
                    HStack(spacing: 10) {
                        Circle()
                            .fill(Theme.stageColor(event.stage))
                            .frame(width: 8, height: 8)
                            .accessibilityHidden(true)
                        Text(event.stage.label)
                            .font(.subheadline)
                        Spacer()
                        Text(event.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(Theme.inkSoft(scheme))
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .hiredCard()
    }

    private func sectionCard<Content: View>(title: String, addAction: @escaping () -> Void,
                                            @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title).font(.headline)
                Spacer()
                Button(action: addAction) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(Theme.blue)
                }
                .accessibilityLabel("Add to \(title)")
            }
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .hiredCard()
    }
}

// MARK: - Small editor sheets

struct InterviewEditorSheet: View {
    let application: Application
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var kind: InterviewKind = .phone
    @State private var date = Date()
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Picker("Type", selection: $kind) {
                    ForEach(InterviewKind.allCases, id: \.self) { Text($0.label).tag($0) }
                }
                DatePicker("When", selection: $date)
                TextField("Notes (interviewer, prep…)", text: $notes, axis: .vertical)
                    .lineLimit(2...4)
            }
            .navigationTitle("New interview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let interview = Interview(kind: kind, scheduledAt: date, notes: notes)
                        interview.application = application
                        context.insert(interview)
                        Haptics.success()
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

struct ContactEditorSheet: View {
    let application: Application
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var title = ""
    @State private var email = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                    .textInputAutocapitalization(.words)
                TextField("Title (optional)", text: $title)
                TextField("Email (optional)", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            .navigationTitle("New contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let trimmed = name.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        let person = JobContact(name: trimmed, title: title, email: email)
                        person.application = application
                        context.insert(person)
                        Haptics.success()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

struct FollowUpEditorSheet: View {
    let application: Application
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var due = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()

    var body: some View {
        NavigationStack {
            Form {
                TextField("What to do (e.g. Email recruiter)", text: $title)
                DatePicker("Due", selection: $due, displayedComponents: .date)
            }
            .navigationTitle("New follow-up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let trimmed = title.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        let task = FollowUp(title: trimmed, dueDate: due)
                        task.application = application
                        context.insert(task)
                        Haptics.success()
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
