import SwiftUI
import SwiftData

/// Add or edit an application. Pass nil to create.
struct ApplicationEditorView: View {
    let application: Application?
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var company = ""
    @State private var role = ""
    @State private var location = ""
    @State private var workMode: WorkMode = .hybrid
    @State private var salaryText = ""
    @State private var link = ""
    @State private var excitement = 3
    @State private var stage: Stage = .applied
    @State private var appliedDate = Date()
    @State private var hasApplied = true
    @State private var notes = ""
    @State private var validationMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Role") {
                    TextField("Company", text: $company)
                        .textInputAutocapitalization(.words)
                    TextField("Role title", text: $role)
                        .textInputAutocapitalization(.words)
                    TextField("Location (optional)", text: $location)
                    Picker("Work mode", selection: $workMode) {
                        ForEach(WorkMode.allCases, id: \.self) { Text($0.label).tag($0) }
                    }
                    TextField("Salary range (optional)", text: $salaryText)
                    TextField("Posting link (optional)", text: $link)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                Section("Status") {
                    Picker("Stage", selection: $stage) {
                        ForEach(Stage.allCases) { s in
                            Label(s.label, systemImage: s.icon).tag(s)
                        }
                    }
                    Toggle("I've applied", isOn: $hasApplied)
                    if hasApplied {
                        DatePicker("Applied on", selection: $appliedDate,
                                   in: ...Date(), displayedComponents: .date)
                    }
                    Stepper(value: $excitement, in: 1...5) {
                        HStack {
                            Text("Excitement")
                            Spacer()
                            Text(String(repeating: "🔥", count: excitement))
                                .accessibilityLabel("\(excitement) out of 5")
                        }
                    }
                }
                Section("Notes") {
                    TextField("Anything worth remembering", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                if let validationMessage {
                    Section {
                        Label(validationMessage, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .font(.subheadline)
                    }
                }
            }
            .navigationTitle(application == nil ? "New application" : "Edit application")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
            .onAppear { populate() }
        }
    }

    private func populate() {
        guard let app = application else {
            hasApplied = stage != .wishlist
            return
        }
        company = app.company
        role = app.role
        location = app.location
        workMode = app.workMode
        salaryText = app.salaryText
        link = app.link
        excitement = app.excitement
        stage = app.stage
        notes = app.notes
        if let d = app.appliedDate {
            appliedDate = d
            hasApplied = true
        } else {
            hasApplied = false
        }
    }

    private func save() {
        let trimmedCompany = company.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedRole = role.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedCompany.isEmpty, !trimmedRole.isEmpty else {
            validationMessage = "Company and role are both required."
            return
        }
        if let app = application {
            let stageChanged = app.stage != stage
            app.company = trimmedCompany
            app.role = trimmedRole
            app.location = location.trimmingCharacters(in: .whitespaces)
            app.workModeRaw = workMode.rawValue
            app.salaryText = salaryText.trimmingCharacters(in: .whitespaces)
            app.link = link.trimmingCharacters(in: .whitespaces)
            app.excitement = excitement
            app.notes = notes
            app.appliedDate = hasApplied ? appliedDate : nil
            if stageChanged {
                app.stageRaw = stage.rawValue
                let event = StageEvent(stage: stage)
                event.application = app
                context.insert(event)
            }
        } else {
            let app = Application(company: trimmedCompany, role: trimmedRole,
                                  location: location.trimmingCharacters(in: .whitespaces),
                                  workMode: workMode,
                                  salaryText: salaryText.trimmingCharacters(in: .whitespaces),
                                  link: link.trimmingCharacters(in: .whitespaces),
                                  excitement: excitement,
                                  appliedDate: hasApplied ? appliedDate : nil,
                                  stage: stage, notes: notes)
            context.insert(app)
            let event = StageEvent(date: hasApplied ? appliedDate : Date(), stage: stage)
            event.application = app
            context.insert(event)
        }
        Haptics.success()
        dismiss()
    }
}
