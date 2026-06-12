import SwiftUI
import SwiftData

struct EditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var resume: Resume

    var body: some View {
        Form {
            Section("Identity") {
                TextField("Full name", text: $resume.fullName)
                    .textContentType(.name)
                TextField("Headline (e.g. Senior Product Designer)", text: $resume.headline)
            }

            Section("Contact") {
                TextField("Email", text: $resume.email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                TextField("Phone", text: $resume.phone)
                    .keyboardType(.phonePad)
                TextField("Location (e.g. Portland, OR)", text: $resume.location)
                TextField("Website", text: $resume.website)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            Section {
                TextField("Two or three sentences that say what you do and what you're best at.", text: $resume.summary, axis: .vertical)
                    .lineLimit(3...8)
            } header: {
                Text("Profile Summary")
            }

            Section {
                ForEach(resume.sortedExperience) { item in
                    NavigationLink {
                        ExperienceEditor(item: item)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.role.isEmpty ? "New role" : item.role)
                                .font(.body.weight(.medium))
                            Text(item.company.isEmpty ? "Company" : item.company)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete { offsets in
                    delete(offsets, from: resume.sortedExperience)
                }
                .onMove { source, destination in
                    move(source, destination, items: resume.sortedExperience) { $0.orderIndex = $1 }
                }
                Button {
                    Haptics.tap()
                    let item = ExperienceItem(orderIndex: (resume.experience.map(\.orderIndex).max() ?? -1) + 1)
                    item.resume = resume
                    modelContext.insert(item)
                } label: {
                    Label("Add Experience", systemImage: "plus")
                }
            } header: {
                Text("Experience")
            } footer: {
                resume.experience.isEmpty
                    ? Text("Most recent first. Use Edit to reorder.")
                    : Text("Swipe to delete · drag in Edit mode to reorder.")
            }

            Section("Education") {
                ForEach(resume.sortedEducation) { item in
                    NavigationLink {
                        EducationEditor(item: item)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.degree.isEmpty ? "New degree" : item.degree)
                                .font(.body.weight(.medium))
                            Text(item.institution.isEmpty ? "Institution" : item.institution)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete { offsets in
                    delete(offsets, from: resume.sortedEducation)
                }
                .onMove { source, destination in
                    move(source, destination, items: resume.sortedEducation) { $0.orderIndex = $1 }
                }
                Button {
                    Haptics.tap()
                    let item = EducationItem(orderIndex: (resume.education.map(\.orderIndex).max() ?? -1) + 1)
                    item.resume = resume
                    modelContext.insert(item)
                } label: {
                    Label("Add Education", systemImage: "plus")
                }
            }

            Section("Skills") {
                ForEach(resume.sortedSkillGroups) { group in
                    NavigationLink {
                        SkillGroupEditor(group: group)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(group.name.isEmpty ? "New group" : group.name)
                                .font(.body.weight(.medium))
                            Text(group.skillList.isEmpty ? "Comma-separated skills" : group.skillList.joined(separator: " · "))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
                .onDelete { offsets in
                    delete(offsets, from: resume.sortedSkillGroups)
                }
                .onMove { source, destination in
                    move(source, destination, items: resume.sortedSkillGroups) { $0.orderIndex = $1 }
                }
                Button {
                    Haptics.tap()
                    let group = SkillGroup(orderIndex: (resume.skillGroups.map(\.orderIndex).max() ?? -1) + 1)
                    group.resume = resume
                    modelContext.insert(group)
                } label: {
                    Label("Add Skill Group", systemImage: "plus")
                }
            }
        }
        .navigationTitle(resume.fullName.isEmpty ? "New Resume" : resume.fullName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                EditButton()
            }
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    PreviewView(resume: resume)
                } label: {
                    Label("Preview", systemImage: "doc.richtext")
                        .labelStyle(.titleAndIcon)
                }
                .accessibilityHint("Shows the formatted document and exports PDF")
            }
        }
        .onDisappear {
            resume.updatedAt = .now
        }
    }

    private func delete<T: PersistentModel>(_ offsets: IndexSet, from items: [T]) {
        for index in offsets where index < items.count {
            modelContext.delete(items[index])
        }
    }

    private func move<T>(_ source: IndexSet, _ destination: Int, items: [T], assign: (T, Int) -> Void) {
        var working = items
        working.move(fromOffsets: source, toOffset: destination)
        for (index, item) in working.enumerated() {
            assign(item, index)
        }
    }
}

// MARK: - Item editors

struct ExperienceEditor: View {
    @Bindable var item: ExperienceItem

    var body: some View {
        Form {
            Section("Role") {
                TextField("Job title", text: $item.role)
                TextField("Company", text: $item.company)
                TextField("Period (e.g. 2021 — Present)", text: $item.period)
            }
            Section {
                TextField("One achievement per line. Start with a verb; add a number if you can.", text: $item.details, axis: .vertical)
                    .lineLimit(4...12)
            } header: {
                Text("Bullets")
            } footer: {
                Text("Each line becomes one bullet on the document.")
            }
        }
        .navigationTitle(item.role.isEmpty ? "Experience" : item.role)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct EducationEditor: View {
    @Bindable var item: EducationItem

    var body: some View {
        Form {
            Section("Education") {
                TextField("Degree (e.g. BSc Computer Science)", text: $item.degree)
                TextField("Institution", text: $item.institution)
                TextField("Period (e.g. 2014 — 2018)", text: $item.period)
                TextField("Note (honors, GPA, thesis…)", text: $item.note, axis: .vertical)
                    .lineLimit(1...4)
            }
        }
        .navigationTitle(item.degree.isEmpty ? "Education" : item.degree)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SkillGroupEditor: View {
    @Bindable var group: SkillGroup

    var body: some View {
        Form {
            Section {
                TextField("Group name (e.g. Languages)", text: $group.name)
                TextField("Skills, comma-separated", text: $group.skills, axis: .vertical)
                    .lineLimit(2...6)
            } footer: {
                Text("Shown as “Group: skill · skill · skill” on the document.")
            }
        }
        .navigationTitle(group.name.isEmpty ? "Skill Group" : group.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
