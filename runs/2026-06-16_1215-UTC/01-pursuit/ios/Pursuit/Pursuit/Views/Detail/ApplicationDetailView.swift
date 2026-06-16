import SwiftUI
import SwiftData

struct ApplicationDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var settings: AppSettings

    @Bindable var application: Application

    @State private var showingEdit = false
    @State private var showingInterviewForm = false
    @State private var editingInterview: Interview?
    @State private var showingContactForm = false
    @State private var editingContact: Contact?
    @State private var toast: ToastData?
    @State private var noteDraft = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                if let salary = Format.salaryRange(min: application.salaryMin, max: application.salaryMax, currencyCode: application.currencyCode) {
                    metaCard(salary: salary)
                }
                tagsSection
                followUpSection
                interviewsSection
                contactsSection
                notesSection
                timelineSection
            }
            .padding(16)
            .padding(.bottom, 32)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle(application.company)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showingEdit = true } label: { Label("Edit", systemImage: "pencil") }
                    Button {
                        application.isArchived.toggle()
                        try? context.save()
                        Haptics.impact(.medium, enabled: settings.hapticsEnabled)
                        toast = ToastData(message: application.isArchived ? "Archived" : "Unarchived",
                                          symbol: "archivebox.fill", tint: Theme.inkSoft)
                    } label: {
                        Label(application.isArchived ? "Unarchive" : "Archive",
                              systemImage: application.isArchived ? "tray.and.arrow.up" : "archivebox")
                    }
                    Divider()
                    Button(role: .destructive) { deleteApplication() } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("More actions")
            }
        }
        .sheet(isPresented: $showingEdit) {
            ApplicationFormView(existing: application) { _ in
                toast = ToastData(message: "Saved", symbol: "checkmark.circle.fill")
            }
        }
        .sheet(isPresented: $showingInterviewForm) {
            InterviewFormView(application: application, existing: editingInterview)
        }
        .sheet(isPresented: $showingContactForm) {
            ContactFormView(application: application, existing: editingContact)
        }
        .toast($toast)
        .onAppear { noteDraft = "" }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(application.role)
                .font(Theme.rounded(24, .bold))
                .foregroundStyle(Theme.ink)
            HStack(spacing: 10) {
                Label(application.workMode.label, systemImage: application.workMode.symbol)
                if !application.location.isEmpty {
                    Text(application.location)
                }
            }
            .font(Theme.rounded(14))
            .foregroundStyle(Theme.inkSoft)

            HStack {
                statusMenu
                Spacer()
                Menu {
                    Picker("Priority", selection: priorityBinding) {
                        ForEach(Priority.allCases) { Label($0.label, systemImage: $0.symbol).tag($0) }
                    }
                } label: {
                    Label(application.priority.label, systemImage: application.priority.symbol)
                        .font(Theme.rounded(13, .semibold))
                        .foregroundStyle(application.priority.color)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(application.priority.color.opacity(0.14), in: Capsule())
                }
                .accessibilityLabel("Priority: \(application.priority.label)")
            }

            HStack {
                Text("How excited are you?")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
                Spacer()
                ExcitementStars(value: application.excitement, interactive: true) { newValue in
                    application.excitement = newValue
                    try? context.save()
                    Haptics.selection(enabled: settings.hapticsEnabled)
                }
            }

            if !application.urlString.isEmpty, let url = sanitizedURL(application.urlString) {
                Button {
                    openURL(url)
                } label: {
                    Label("Open job posting", systemImage: "safari")
                        .font(Theme.rounded(14, .semibold))
                }
                .accessibilityHint("Opens the posting in your browser")
            }

            HStack(spacing: 6) {
                Image(systemName: application.source.symbol)
                Text("Source: \(application.source.label)")
                if let applied = application.appliedDate {
                    Text("•")
                    Text("Applied \(Format.date(applied))")
                }
            }
            .font(Theme.rounded(12, .medium))
            .foregroundStyle(Theme.inkFaint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: 18)
    }

    private var statusMenu: some View {
        Menu {
            ForEach(AppStatus.pipelineOrder) { status in
                Button {
                    changeStatus(to: status)
                } label: {
                    Label(status.label, systemImage: status.symbol)
                }
            }
        } label: {
            StatusBadge(status: application.status)
        }
        .accessibilityLabel("Change status, current \(application.status.label)")
    }

    private var priorityBinding: Binding<Priority> {
        Binding(
            get: { application.priority },
            set: { newValue in
                application.priority = newValue
                try? context.save()
                Haptics.selection(enabled: settings.hapticsEnabled)
            }
        )
    }

    private func metaCard(salary: String) -> some View {
        HStack(spacing: 0) {
            metaItem(title: "Salary", value: salary, symbol: "dollarsign.circle")
            Divider().frame(height: 36)
            metaItem(title: "Interviews", value: "\(application.interviews.count)", symbol: "person.2")
            Divider().frame(height: 36)
            metaItem(title: "Contacts", value: "\(application.contacts.count)", symbol: "person.crop.circle")
        }
        .cardStyle(padding: 14)
    }

    private func metaItem(title: String, value: String, symbol: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(Theme.rounded(16, .bold))
                .foregroundStyle(Theme.ink)
                .lineLimit(1).minimumScaleFactor(0.7)
            Text(title)
                .font(Theme.rounded(11, .medium))
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(value)")
    }

    // MARK: - Tags

    @ViewBuilder
    private var tagsSection: some View {
        if !application.tags.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                sectionTitle("Tags", symbol: "tag")
                FlowLayout(spacing: 8, lineSpacing: 8) {
                    ForEach(application.tags.sorted { $0.name < $1.name }) { tag in
                        TagChip(tag: tag)
                    }
                }
            }
            .cardStyle()
        }
    }

    // MARK: - Follow-up

    private var followUpSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Follow-up reminder", symbol: "bell")
            Toggle(isOn: followUpBinding) {
                Text("Remind me to follow up")
                    .font(Theme.rounded(15))
                    .foregroundStyle(Theme.ink)
            }
            .tint(Theme.accent)
            if application.followUpEnabled {
                DatePicker("On", selection: followUpDateBinding, displayedComponents: .date)
                    .font(Theme.rounded(14))
            }
        }
        .cardStyle()
    }

    private var followUpBinding: Binding<Bool> {
        Binding(
            get: { application.followUpEnabled },
            set: { on in
                application.followUpEnabled = on
                if on && application.followUpDate == nil {
                    application.followUpDate = Calendar.current.date(byAdding: .day, value: settings.followUpDays, to: Date())
                    let ev = ActivityEvent(kind: .followUp, detail: "Follow-up reminder set")
                    ev.application = application
                    context.insert(ev)
                    application.events.append(ev)
                }
                try? context.save()
                Haptics.selection(enabled: settings.hapticsEnabled)
            }
        )
    }

    private var followUpDateBinding: Binding<Date> {
        Binding(
            get: { application.followUpDate ?? Date() },
            set: { application.followUpDate = $0; try? context.save() }
        )
    }

    // MARK: - Interviews

    private var interviewsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                sectionTitle("Interviews", symbol: "person.2")
                Spacer()
                Button {
                    editingInterview = nil
                    showingInterviewForm = true
                } label: { Image(systemName: "plus.circle.fill").font(.system(size: 20)) }
                .accessibilityLabel("Add interview")
            }
            if application.interviews.isEmpty {
                Text("No interviews yet. Add rounds as they're scheduled.")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
            } else {
                ForEach(application.sortedInterviews) { interview in
                    interviewRow(interview)
                    if interview.id != application.sortedInterviews.last?.id {
                        Divider()
                    }
                }
            }
        }
        .cardStyle()
    }

    private func interviewRow(_ interview: Interview) -> some View {
        Button {
            editingInterview = interview
            showingInterviewForm = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: interview.mode.symbol)
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 3) {
                    Text(interview.roundName)
                        .font(Theme.rounded(15, .semibold))
                        .foregroundStyle(Theme.ink)
                    HStack(spacing: 6) {
                        if let date = interview.scheduledDate {
                            Text(Format.dateTime(date))
                        } else {
                            Text("Unscheduled")
                        }
                        if interview.durationMin > 0 {
                            Text("• \(interview.durationMin) min")
                        }
                    }
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkSoft)
                }
                Spacer()
                Label(interview.outcome.label, systemImage: interview.outcome.symbol)
                    .labelStyle(.iconOnly)
                    .font(.system(size: 16))
                    .foregroundStyle(interview.outcome.color)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button { editingInterview = interview; showingInterviewForm = true } label: { Label("Edit", systemImage: "pencil") }
            Button(role: .destructive) { delete(interview) } label: { Label("Delete", systemImage: "trash") }
        }
        .accessibilityLabel("\(interview.roundName), \(interview.outcome.label)")
        .accessibilityHint("Tap to edit, long press for more")
    }

    // MARK: - Contacts

    private var contactsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                sectionTitle("Contacts", symbol: "person.crop.circle")
                Spacer()
                Button {
                    editingContact = nil
                    showingContactForm = true
                } label: { Image(systemName: "plus.circle.fill").font(.system(size: 20)) }
                .accessibilityLabel("Add contact")
            }
            if application.contacts.isEmpty {
                Text("No contacts yet. Add recruiters or referrals.")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
            } else {
                ForEach(application.contacts.sorted { $0.name < $1.name }) { contact in
                    contactRow(contact)
                    if contact.id != application.contacts.sorted(by: { $0.name < $1.name }).last?.id {
                        Divider()
                    }
                }
            }
        }
        .cardStyle()
    }

    private func contactRow(_ contact: Contact) -> some View {
        Button {
            editingContact = contact
            showingContactForm = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: contact.role.symbol)
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 3) {
                    Text(contact.name)
                        .font(Theme.rounded(15, .semibold))
                        .foregroundStyle(Theme.ink)
                    Text(contact.email.isEmpty ? contact.role.label : contact.email)
                        .font(Theme.rounded(12))
                        .foregroundStyle(Theme.inkSoft)
                        .lineLimit(1)
                }
                Spacer()
                if !contact.email.isEmpty, let url = URL(string: "mailto:\(contact.email)") {
                    Button { openURL(url) } label: {
                        Image(systemName: "envelope")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Theme.accent)
                    .accessibilityLabel("Email \(contact.name)")
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button { editingContact = contact; showingContactForm = true } label: { Label("Edit", systemImage: "pencil") }
            Button(role: .destructive) { delete(contact) } label: { Label("Delete", systemImage: "trash") }
        }
        .accessibilityLabel("\(contact.name), \(contact.role.label)")
        .accessibilityHint("Tap to edit, long press for more")
    }

    // MARK: - Notes

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Notes", symbol: "note.text")
            TextEditor(text: notesBinding)
                .font(Theme.rounded(15))
                .frame(minHeight: 90)
                .padding(8)
                .background(Theme.surfaceAlt, in: RoundedRectangle(cornerRadius: Theme.radiusS))
                .overlay(alignment: .topLeading) {
                    if application.notes.isEmpty {
                        Text("Jot down impressions, comp details, next steps…")
                            .font(Theme.rounded(15))
                            .foregroundStyle(Theme.inkFaint)
                            .padding(.horizontal, 13)
                            .padding(.vertical, 16)
                            .allowsHitTesting(false)
                    }
                }
            HStack {
                TextField("Log an activity note…", text: $noteDraft, axis: .vertical)
                    .font(Theme.rounded(14))
                    .lineLimit(1...3)
                Button {
                    logNote()
                } label: {
                    Image(systemName: "arrow.up.circle.fill").font(.system(size: 24))
                }
                .disabled(noteDraft.trimmingCharacters(in: .whitespaces).isEmpty)
                .accessibilityLabel("Add note to timeline")
            }
        }
        .cardStyle()
    }

    private var notesBinding: Binding<String> {
        Binding(
            get: { application.notes },
            set: { application.notes = $0; try? context.save() }
        )
    }

    // MARK: - Timeline

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Timeline", symbol: "clock.arrow.circlepath")
            if application.events.isEmpty {
                Text("Activity will appear here as you update this application.")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
            } else {
                ForEach(application.sortedEvents) { event in
                    timelineRow(event, isLast: event.id == application.sortedEvents.last?.id)
                }
            }
        }
        .cardStyle()
    }

    private func timelineRow(_ event: ActivityEvent, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                Circle()
                    .fill(event.kind.color)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Image(systemName: event.kind.symbol)
                            .font(.system(size: 6, weight: .bold))
                            .foregroundStyle(.white)
                    )
                if !isLast {
                    Rectangle()
                        .fill(Theme.hairline)
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 12)
            VStack(alignment: .leading, spacing: 2) {
                Text(event.detail)
                    .font(Theme.rounded(14, .medium))
                    .foregroundStyle(Theme.ink)
                Text(Format.dateTime(event.date))
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkFaint)
            }
            .padding(.bottom, isLast ? 0 : 12)
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(event.detail), \(Format.dateTime(event.date))")
    }

    // MARK: - Helpers

    private func sectionTitle(_ text: String, symbol: String) -> some View {
        Label(text, systemImage: symbol)
            .font(Theme.rounded(16, .bold))
            .foregroundStyle(Theme.ink)
    }

    private func sanitizedURL(_ string: String) -> URL? {
        let trimmed = string.trimmingCharacters(in: .whitespaces)
        if trimmed.lowercased().hasPrefix("http://") || trimmed.lowercased().hasPrefix("https://") {
            return URL(string: trimmed)
        }
        return URL(string: "https://" + trimmed)
    }

    private func changeStatus(to status: AppStatus) {
        guard application.status != status else { return }
        application.status = status
        if status.isSubmitted && application.appliedDate == nil {
            application.appliedDate = Date()
        }
        let ev = ActivityEvent(kind: .statusChanged, detail: "Moved to \(status.label)", status: status)
        ev.application = application
        context.insert(ev)
        application.events.append(ev)
        try? context.save()
        Haptics.notify(.success, enabled: settings.hapticsEnabled)
        toast = ToastData(message: "Moved to \(status.label)", symbol: status.symbol, tint: status.color)
    }

    private func logNote() {
        let text = noteDraft.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        let ev = ActivityEvent(kind: .note, detail: text)
        ev.application = application
        context.insert(ev)
        application.events.append(ev)
        try? context.save()
        noteDraft = ""
        Haptics.impact(.light, enabled: settings.hapticsEnabled)
        toast = ToastData(message: "Note added", symbol: "note.text", tint: Theme.accent)
    }

    private func delete(_ interview: Interview) {
        application.interviews.removeAll { $0.id == interview.id }
        context.delete(interview)
        try? context.save()
        Haptics.impact(.medium, enabled: settings.hapticsEnabled)
    }

    private func delete(_ contact: Contact) {
        application.contacts.removeAll { $0.id == contact.id }
        context.delete(contact)
        try? context.save()
        Haptics.impact(.medium, enabled: settings.hapticsEnabled)
    }

    private func deleteApplication() {
        context.delete(application)
        try? context.save()
        Haptics.notify(.warning, enabled: settings.hapticsEnabled)
        dismiss()
    }
}
