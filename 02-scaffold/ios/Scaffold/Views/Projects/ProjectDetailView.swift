import SwiftUI
import SwiftData
import PhotosUI

struct ProjectDetailView: View {
    @Environment(\.modelContext) private var context
    @Bindable var project: Project

    @State private var showEdit = false
    @State private var showAddTask = false
    @State private var showAddMaterial = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var newTaskTitle = ""
    @State private var isAddingTask = false

    var body: some View {
        List {
            // Header section
            Section {
                statusBudgetRow
            }

            // Progress
            if !project.tasks.isEmpty {
                Section("Progress") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("\(project.tasks.filter { $0.status == .done }.count)/\(project.tasks.count) tasks done")
                                .font(.subheadline)
                                .foregroundColor(ScaffoldTheme.secondaryLabel)
                            Spacer()
                            Text("\(Int(project.taskCompletionFraction * 100))%")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(ScaffoldTheme.accent)
                        }
                        ProgressView(value: project.taskCompletionFraction)
                            .tint(ScaffoldTheme.accent)
                    }
                }
            }

            // Tasks
            Section {
                ForEach(project.tasks.sorted(by: { $0.createdAt < $1.createdAt })) { task in
                    TaskRowView(task: task)
                }
                .onDelete { idx in deleteTasks(at: idx) }

                if isAddingTask {
                    HStack {
                        TextField("Task description", text: $newTaskTitle, onCommit: saveNewTask)
                            .accessibilityLabel("New task description")
                        Button(action: saveNewTask) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(ScaffoldTheme.accent)
                        }
                        .accessibilityLabel("Save task")
                    }
                }

                Button(action: { isAddingTask = true }) {
                    Label("Add Task", systemImage: "plus.circle")
                        .foregroundColor(ScaffoldTheme.accent)
                }
                .accessibilityLabel("Add task")
            } header: {
                Text("Tasks")
            }

            // Materials / Budget
            Section {
                HStack {
                    budgetStat("Budget", String(format: "$%.0f", project.budget))
                    Divider()
                    budgetStat("Spent", String(format: "$%.0f", project.actualCost))
                    Divider()
                    budgetStat(project.budgetRemaining >= 0 ? "Left" : "Over",
                               String(format: "$%.0f", abs(project.budgetRemaining)))
                        .foregroundColor(project.budgetRemaining < 0 ? .red : ScaffoldTheme.secondaryLabel)
                }
                .frame(height: 56)

                if project.budget > 0 {
                    ProgressView(value: min(project.budgetUsedFraction, 1.0))
                        .tint(project.budgetUsedFraction > 1 ? .red : ScaffoldTheme.accent)
                        .accessibilityLabel("Budget used: \(Int(project.budgetUsedFraction * 100))%")
                }

                ForEach(project.materials.sorted(by: { $0.createdAt < $1.createdAt })) { material in
                    MaterialRowView(material: material)
                }
                .onDelete { idx in deleteMaterials(at: idx) }

                Button(action: { showAddMaterial = true }) {
                    Label("Add Material", systemImage: "plus.circle")
                        .foregroundColor(ScaffoldTheme.accent)
                }
                .accessibilityLabel("Add material or supply")
            } header: {
                Text("Materials & Budget")
            }

            // Photos
            Section("Before & After Photos") {
                if !project.photos.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(project.photos.sorted(by: { $0.dateTaken < $1.dateTaken })) { photo in
                                PhotoThumbnailView(photo: photo)
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
                    .listRowBackground(Color.clear)
                }

                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Label("Add Photo", systemImage: "photo.badge.plus")
                        .foregroundColor(ScaffoldTheme.accent)
                }
                .accessibilityLabel("Add before or after photo")
                .onChange(of: selectedPhotoItem) { _, item in
                    guard let item else { return }
                    Task {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            await MainActor.run {
                                let filename = ScaffoldPhotoStore.shared.newFilename()
                                try? ScaffoldPhotoStore.shared.save(image, filename: filename)
                                let photo = ProjectPhoto(filename: filename, project: project)
                                context.insert(photo)
                                try? context.save()
                            }
                        }
                    }
                }
            }

            // Notes
            if !project.notes.isEmpty {
                Section("Notes") {
                    Text(project.notes)
                        .font(.body)
                        .foregroundColor(ScaffoldTheme.label)
                }
            }
        }
        .navigationTitle(project.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showEdit = true }) {
                    Image(systemName: "pencil")
                }
                .accessibilityLabel("Edit project")
            }
        }
        .sheet(isPresented: $showEdit) {
            AddEditProjectView(project: project, room: project.room!)
        }
        .sheet(isPresented: $showAddMaterial) {
            AddMaterialView(project: project)
        }
    }

    private var statusBudgetRow: some View {
        HStack(spacing: 16) {
            Label(project.status.rawValue, systemImage: project.status.icon)
                .font(.subheadline.weight(.medium))
                .foregroundColor(ScaffoldTheme.statusColor(project.status))

            Spacer()

            if let target = project.targetDate {
                Label(target.formatted(.dateTime.month(.abbreviated).day().year()), systemImage: "calendar")
                    .font(.caption)
                    .foregroundColor(target < Date() && project.status != .complete ? .red : ScaffoldTheme.secondaryLabel)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Status: \(project.status.rawValue)")
    }

    private func budgetStat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(ScaffoldTheme.label)
            Text(label)
                .font(.caption2)
                .foregroundColor(ScaffoldTheme.secondaryLabel)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    private func saveNewTask() {
        let t = newTaskTitle.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { isAddingTask = false; return }
        let task = ProjectTask(title: t, project: project)
        context.insert(task)
        try? context.save()
        newTaskTitle = ""
        isAddingTask = false
    }

    private func deleteTasks(at offsets: IndexSet) {
        let sorted = project.tasks.sorted(by: { $0.createdAt < $1.createdAt })
        for i in offsets { context.delete(sorted[i]) }
        try? context.save()
    }

    private func deleteMaterials(at offsets: IndexSet) {
        let sorted = project.materials.sorted(by: { $0.createdAt < $1.createdAt })
        for i in offsets { context.delete(sorted[i]) }
        try? context.save()
    }
}

struct TaskRowView: View {
    @Environment(\.modelContext) private var context
    @Bindable var task: ProjectTask

    var body: some View {
        HStack(spacing: 12) {
            Button(action: cycleStatus) {
                Image(systemName: task.status == .done ? "checkmark.circle.fill" :
                      task.status == .inProgress ? "circle.fill" : "circle")
                    .foregroundColor(task.status == .done ? .green :
                                     task.status == .inProgress ? ScaffoldTheme.accent : ScaffoldTheme.secondaryLabel)
                    .font(.title3)
            }
            .accessibilityLabel("Toggle task status, currently \(task.status.rawValue)")

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.subheadline)
                    .foregroundColor(task.status == .done ? ScaffoldTheme.secondaryLabel : ScaffoldTheme.label)
                    .strikethrough(task.status == .done)
                if !task.notes.isEmpty {
                    Text(task.notes)
                        .font(.caption)
                        .foregroundColor(ScaffoldTheme.secondaryLabel)
                }
            }
            Spacer()
            Text(task.status.rawValue)
                .font(.caption2)
                .foregroundColor(task.status == .done ? .green : task.status == .inProgress ? ScaffoldTheme.accent : ScaffoldTheme.secondaryLabel)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(task.title), \(task.status.rawValue)")
    }

    private func cycleStatus() {
        switch task.status {
        case .todo: task.status = .inProgress
        case .inProgress: task.status = .done
        case .done: task.status = .todo
        }
        try? context.save()
    }
}

struct MaterialRowView: View {
    @Environment(\.modelContext) private var context
    @Bindable var material: Material

    var body: some View {
        HStack {
            Button(action: { material.purchased.toggle(); try? context.save() }) {
                Image(systemName: material.purchased ? "cart.fill.badge.checkmark" : "cart.badge.plus")
                    .foregroundColor(material.purchased ? .green : ScaffoldTheme.accent)
            }
            .accessibilityLabel(material.purchased ? "Mark as not purchased" : "Mark as purchased")

            VStack(alignment: .leading, spacing: 2) {
                Text(material.name)
                    .font(.subheadline)
                    .foregroundColor(ScaffoldTheme.label)
                if !material.vendor.isEmpty {
                    Text(material.vendor)
                        .font(.caption)
                        .foregroundColor(ScaffoldTheme.secondaryLabel)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                if material.unitCost > 0 {
                    Text(String(format: "$%.2f", material.totalCost))
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(ScaffoldTheme.label)
                    Text("\(material.quantity) × $\(String(format: "%.2f", material.unitCost))")
                        .font(.caption2)
                        .foregroundColor(ScaffoldTheme.secondaryLabel)
                } else {
                    Text("Qty: \(material.quantity)")
                        .font(.caption)
                        .foregroundColor(ScaffoldTheme.secondaryLabel)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(material.name), \(material.purchased ? "purchased" : "not purchased")")
    }
}

struct PhotoThumbnailView: View {
    let photo: ProjectPhoto
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let img = image {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle().fill(ScaffoldTheme.secondaryBackground)
                    .overlay(Image(systemName: "photo").foregroundColor(ScaffoldTheme.secondaryLabel))
            }
        }
        .frame(width: 100, height: 80)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .onAppear { image = ScaffoldPhotoStore.shared.load(filename: photo.filename) }
        .accessibilityLabel(photo.caption.isEmpty ? "Project photo" : photo.caption)
    }
}
