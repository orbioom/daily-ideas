import SwiftUI
import SwiftData

/// Add or edit an application. When `existing` is nil it creates a new one.
struct ApplicationFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    var existing: Application?
    var onSaved: ((Application) -> Void)? = nil

    @State private var company = ""
    @State private var role = ""
    @State private var location = ""
    @State private var workMode: WorkMode = .remote
    @State private var status: AppStatus = .saved
    @State private var source: AppSource = .linkedIn
    @State private var priority: Priority = .med
    @State private var excitement = 3
    @State private var urlString = ""
    @State private var salaryMinText = ""
    @State private var salaryMaxText = ""
    @State private var currency = "USD"
    @State private var notes = ""
    @State private var hasApplied = false
    @State private var appliedDate = Date()

    @Query(sort: \Tag.name) private var allTags: [Tag]
    @State private var selectedTagIDs: Set<UUID> = []

    private var isEditing: Bool { existing != nil }
    private var trimmedCompany: String { company.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var trimmedRole: String { role.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canSave: Bool { !trimmedCompany.isEmpty && !trimmedRole.isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Role") {
                    TextField("Company", text: $company)
                        .textInputAutocapitalization(.words)
                    TextField("Title / role", text: $role)
                        .textInputAutocapitalization(.words)
                    TextField("Location", text: $location)
                    Picker("Work mode", selection: $workMode) {
                        ForEach(WorkMode.allCases) { Label($0.label, systemImage: $0.symbol).tag($0) }
                    }
                }

                Section("Pipeline") {
                    Picker("Status", selection: $status) {
                        ForEach(AppStatus.pipelineOrder) { Label($0.label, systemImage: $0.symbol).tag($0) }
                    }
                    Picker("Source", selection: $source) {
                        ForEach(AppSource.allCases) { Label($0.label, systemImage: $0.symbol).tag($0) }
                    }
                    Picker("Priority", selection: $priority) {
                        ForEach(Priority.allCases) { Label($0.label, systemImage: $0.symbol).tag($0) }
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Excitement").font(Theme.rounded(15))
                        ExcitementStars(value: excitement, interactive: true) { newValue in
                            excitement = newValue
                            Haptics.selection(enabled: settings.hapticsEnabled)
                        }
                    }
                    Toggle("Mark as applied", isOn: $hasApplied)
                    if hasApplied {
                        DatePicker("Applied on", selection: $appliedDate, displayedComponents: .date)
                    }
                }

                Section("Compensation") {
                    HStack {
                        TextField("Min", text: $salaryMinText)
                            .keyboardType(.numberPad)
                        Text("–").foregroundStyle(Theme.inkFaint)
                        TextField("Max", text: $salaryMaxText)
                            .keyboardType(.numberPad)
                    }
                    Picker("Currency", selection: $currency) {
                        ForEach(AppSettings.currencyOptions, id: \.self) { Text($0).tag($0) }
                    }
                }

                Section("Link") {
                    TextField("Job posting URL", text: $urlString)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                if !allTags.isEmpty {
                    Section("Tags") {
                        FlowLayout(spacing: 8, lineSpacing: 8) {
                            ForEach(allTags) { tag in
                                tagToggle(tag)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("Notes") {
                    TextField("Anything worth remembering…", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(isEditing ? "Edit Application" : "New Application")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                        .fontWeight(.semibold)
                }
            }
            .onAppear(perform: loadIfNeeded)
        }
    }

    private func tagToggle(_ tag: Tag) -> some View {
        let isOn = selectedTagIDs.contains(tag.id)
        return Button {
            if isOn { selectedTagIDs.remove(tag.id) } else { selectedTagIDs.insert(tag.id) }
            Haptics.selection(enabled: settings.hapticsEnabled)
        } label: {
            Text(tag.name)
                .font(Theme.rounded(13, .medium))
                .foregroundStyle(isOn ? .white : tag.color)
                .padding(.horizontal, 11)
                .padding(.vertical, 6)
                .background(isOn ? tag.color : tag.color.opacity(0.15), in: Capsule())
                .overlay(Capsule().stroke(tag.color.opacity(isOn ? 0 : 0.4), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Tag \(tag.name)")
        .accessibilityValue(isOn ? "Selected" : "Not selected")
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    private func loadIfNeeded() {
        guard let app = existing else {
            currency = settings.defaultCurrency
            return
        }
        company = app.company
        role = app.role
        location = app.location
        workMode = app.workMode
        status = app.status
        source = app.source
        priority = app.priority
        excitement = app.excitement
        urlString = app.urlString
        currency = app.currencyCode
        notes = app.notes
        salaryMinText = decimalText(app.salaryMin)
        salaryMaxText = decimalText(app.salaryMax)
        if let applied = app.appliedDate {
            hasApplied = true
            appliedDate = applied
        }
        selectedTagIDs = Set(app.tags.map(\.id))
    }

    private func decimalText(_ value: Decimal?) -> String {
        guard let value else { return "" }
        return NSDecimalNumber(decimal: value).stringValue
    }

    private func parseDecimal(_ text: String) -> Decimal? {
        let cleaned = text.filter { $0.isNumber || $0 == "." }
        guard !cleaned.isEmpty else { return nil }
        return Decimal(string: cleaned)
    }

    private func save() {
        guard canSave else { return }
        let minD = parseDecimal(salaryMinText)
        let maxD = parseDecimal(salaryMaxText)
        let appliedValue: Date? = hasApplied ? appliedDate : nil
        let selectedTags = allTags.filter { selectedTagIDs.contains($0.id) }

        if let app = existing {
            app.company = trimmedCompany
            app.role = trimmedRole
            app.location = location.trimmingCharacters(in: .whitespaces)
            app.workMode = workMode
            app.source = source
            app.priority = priority
            app.excitement = min(5, max(1, excitement))
            app.urlString = urlString.trimmingCharacters(in: .whitespaces)
            app.currencyCode = currency
            app.notes = notes
            app.salaryMin = minD
            app.salaryMax = maxD
            app.appliedDate = appliedValue
            app.tags = selectedTags
            if app.status != status {
                app.status = status
                let ev = ActivityEvent(kind: .statusChanged, detail: "Moved to \(status.label)", status: status)
                ev.application = app
                context.insert(ev)
                app.events.append(ev)
            }
            try? context.save()
            Haptics.notify(.success, enabled: settings.hapticsEnabled)
            onSaved?(app)
        } else {
            let app = Application(
                company: trimmedCompany,
                role: trimmedRole,
                location: location.trimmingCharacters(in: .whitespaces),
                workMode: workMode,
                status: status,
                salaryMin: minD,
                salaryMax: maxD,
                currencyCode: currency,
                source: source,
                urlString: urlString.trimmingCharacters(in: .whitespaces),
                appliedDate: appliedValue,
                priority: priority,
                excitement: min(5, max(1, excitement)),
                notes: notes
            )
            context.insert(app)
            app.tags = selectedTags

            let created = ActivityEvent(kind: .created, detail: "Added \(trimmedCompany) — \(trimmedRole)")
            created.application = app
            context.insert(created)
            app.events.append(created)

            if status.isSubmitted {
                let ev = ActivityEvent(kind: .statusChanged, date: appliedValue ?? Date(),
                                       detail: "Status set to \(status.label)", status: status)
                ev.application = app
                context.insert(ev)
                app.events.append(ev)
            }
            try? context.save()
            Haptics.notify(.success, enabled: settings.hapticsEnabled)
            onSaved?(app)
        }
        dismiss()
    }
}
