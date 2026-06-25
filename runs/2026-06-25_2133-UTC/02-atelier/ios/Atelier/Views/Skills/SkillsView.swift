import SwiftUI
import SwiftData

struct SkillsView: View {
    @Query(sort: \ArtSkill.name) private var skills: [ArtSkill]
    @Environment(\.modelContext) private var context
    @State private var showingAdd = false
    @State private var categoryFilter: SkillCategory?
    @State private var editSkill: ArtSkill?

    private var filtered: [ArtSkill] {
        guard let c = categoryFilter else { return skills }
        return skills.filter { $0.category == c }
    }

    private var groupedByStatus: [(SkillStatus, [ArtSkill])] {
        let order: [SkillStatus] = [.mastered, .comfortable, .practicing, .learning, .notStarted]
        return order.compactMap { status in
            let arr = filtered.filter { $0.status == status }
            return arr.isEmpty ? nil : (status, arr)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if skills.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 0) {
                        filterBar
                        skillList
                    }
                }
            }
            .navigationTitle("Skills")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(AtelierTheme.amber)
                    }
                    .accessibilityLabel("Add skill")
                }
            }
            .sheet(isPresented: $showingAdd) { SkillFormView(skill: nil) }
            .sheet(item: $editSkill) { skill in SkillFormView(skill: skill) }
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button("All") { categoryFilter = nil }
                    .chipStyle(isSelected: categoryFilter == nil, color: AtelierTheme.amber)

                ForEach(SkillCategory.allCases) { cat in
                    Button(cat.rawValue) { categoryFilter = cat }
                        .chipStyle(isSelected: categoryFilter == cat, color: AtelierTheme.amber)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    private var skillList: some View {
        List {
            ForEach(groupedByStatus, id: \.0) { status, statusSkills in
                Section {
                    ForEach(statusSkills) { skill in
                        SkillRowView(skill: skill)
                            .onTapGesture { editSkill = skill }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    context.delete(skill); try? context.save()
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                } header: {
                    HStack {
                        Circle().fill(status.color).frame(width: 10, height: 10).accessibilityHidden(true)
                        Text(status.rawValue).font(.subheadline.bold())
                        Spacer()
                        Text("\(statusSkills.count)").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "list.star")
                .font(.system(size: 56))
                .foregroundStyle(AtelierTheme.amber.opacity(0.5))
                .accessibilityHidden(true)
            Text("No skills yet")
                .font(.title3.bold())
            Text("Add skills to track your progress from learning to mastered.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct SkillRowView: View {
    let skill: ArtSkill

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(skill.status.color.opacity(0.15)).frame(width: 44, height: 44)
                Image(systemName: skill.category.sfSymbol)
                    .foregroundStyle(skill.status.color)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(skill.name).font(.subheadline.bold())
                Text(skill.category.rawValue).font(.caption).foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Circle()
                    .fill(skill.status.color)
                    .frame(width: 10, height: 10)
                    .accessibilityHidden(true)
                ProgressView(value: skill.status.progress)
                    .tint(skill.status.color)
                    .frame(width: 60)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(skill.name), \(skill.category.rawValue), \(skill.status.rawValue)")
    }
}

private extension View {
    func chipStyle(isSelected: Bool, color: Color) -> some View {
        self
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? color : Color(.secondarySystemBackground))
            .foregroundStyle(isSelected ? AtelierTheme.ink : .primary)
            .clipShape(Capsule())
    }
}

struct SkillFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let skill: ArtSkill?

    @State private var name: String
    @State private var category: SkillCategory
    @State private var status: SkillStatus
    @State private var notes: String
    @State private var showError = false

    init(skill: ArtSkill?) {
        self.skill = skill
        _name = State(initialValue: skill?.name ?? "")
        _category = State(initialValue: skill?.category ?? .drawing)
        _status = State(initialValue: skill?.status ?? .notStarted)
        _notes = State(initialValue: skill?.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Skill") {
                    TextField("Name", text: $name)
                    Picker("Category", selection: $category) {
                        ForEach(SkillCategory.allCases) { c in
                            Label(c.rawValue, systemImage: c.sfSymbol).tag(c)
                        }
                    }
                    Picker("Status", selection: $status) {
                        ForEach(SkillStatus.allCases) { s in Text(s.rawValue).tag(s) }
                    }
                }
                Section("Notes") {
                    TextField("Notes", text: $notes)
                }
                Section("Progress") {
                    HStack {
                        Text("Progress")
                        Spacer()
                        ProgressView(value: status.progress)
                            .tint(status.color)
                            .frame(width: 100)
                        Text("\(Int(status.progress * 100))%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(skill == nil ? "Add Skill" : "Edit Skill")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                        .fontWeight(.semibold)
                        .foregroundStyle(AtelierTheme.amber)
                }
            }
            .alert("Please enter a skill name.", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { showError = true; return }
        if let s = skill {
            s.name = trimmed; s.category = category; s.status = status; s.notes = notes
        } else {
            context.insert(ArtSkill(name: trimmed, category: category, status: status, notes: notes))
        }
        try? context.save()
        dismiss()
    }
}
