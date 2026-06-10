import SwiftUI
import SwiftData

struct ProjectsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \CollageProject.updatedAt, order: .reverse) private var projects: [CollageProject]

    @State private var showNew = false
    @State private var target: CollageProject?

    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if projects.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(projects) { p in
                                projectCard(p)
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Mosaic")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showNew = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("New collage")
                }
            }
            .navigationDestination(item: $target) { project in
                EditorView(project: project, context: context)
            }
            .sheet(isPresented: $showNew) {
                NewCollageSheet { template, aspect in
                    createProject(template: template, aspect: aspect)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            EmptyStateView(icon: "square.grid.2x2",
                           title: "No collages yet",
                           message: "Create your first collage — pick a layout, drop in photos, and export without a watermark.")
            Button { showNew = true } label: {
                Label("New collage", systemImage: "plus")
            }
            .buttonStyle(InkButtonStyle())
            .padding(.horizontal, 60)
        }
    }

    private func projectCard(_ p: CollageProject) -> some View {
        Button { target = p } label: {
            VStack(alignment: .leading, spacing: 0) {
                ZStack {
                    Rectangle().fill(Brand.dynamic(0xE3E5EC, 0x2A2D35))
                    if let thumb = ImageStore.load(p.thumbnailFile) {
                        Image(uiImage: thumb).resizable().scaledToFill()
                    } else {
                        Image(systemName: "photo.stack").font(.largeTitle).foregroundStyle(Brand.text3)
                    }
                }
                .frame(height: 150)
                .clipped()
                VStack(alignment: .leading, spacing: 2) {
                    Text(p.name).font(.subheadline.weight(.semibold)).foregroundStyle(Brand.text).lineLimit(1)
                    Text("\(p.filledCount)/\(p.template.cellCount) photos · \(p.aspect.label)")
                        .font(.caption2).foregroundStyle(Brand.text2)
                }
                .padding(10)
            }
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Brand.glassStroke.opacity(0.4), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) { delete(p) } label: { Label("Delete", systemImage: "trash") }
        }
        .accessibilityLabel("\(p.name), \(p.filledCount) of \(p.template.cellCount) photos")
    }

    private func createProject(template: Template, aspect: CanvasAspect) {
        let project = CollageProject(name: defaultName(), templateID: template.id, aspect: aspect)
        for i in 0..<template.cellCount {
            let cell = CollageCell(order: i)
            cell.project = project
            project.cells.append(cell)
        }
        context.insert(project)
        try? context.save()
        target = project
        Haptics.tap()
    }

    private func defaultName() -> String {
        let f = DateFormatter(); f.dateFormat = "MMM d"
        return "Collage \(f.string(from: .now))"
    }

    private func delete(_ p: CollageProject) {
        for cell in p.cells { ImageStore.delete(cell.imageFile) }
        ImageStore.delete(p.thumbnailFile)
        context.delete(p)
        try? context.save()
        Haptics.warning()
    }
}

struct NewCollageSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onCreate: (Template, CanvasAspect) -> Void

    @State private var template = Templates.all[3]
    @State private var aspect: CanvasAspect = .square

    private let columns = [GridItem(.adaptive(minimum: 80), spacing: 12)]

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("LAYOUT").font(Brand.mono(12, weight: .medium)).tracking(1.4).foregroundStyle(Brand.text3)
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(Templates.all) { t in
                                Button { template = t; Haptics.selection() } label: {
                                    VStack(spacing: 5) {
                                        TemplateThumb(template: t, selected: template.id == t.id)
                                            .frame(width: 72, height: 72)
                                        Text(t.name).font(.caption2)
                                            .foregroundStyle(template.id == t.id ? Brand.text : Brand.text3)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        Text("CANVAS").font(Brand.mono(12, weight: .medium)).tracking(1.4).foregroundStyle(Brand.text3)
                            .padding(.top, 8)
                        HStack(spacing: 8) {
                            ForEach(CanvasAspect.allCases) { a in
                                Button { aspect = a; Haptics.selection() } label: {
                                    Text(a.label).font(.caption.weight(.medium))
                                        .padding(.horizontal, 12).padding(.vertical, 8)
                                        .foregroundStyle(aspect == a ? .white : Brand.text2)
                                        .background(aspect == a ? AnyShapeStyle(Brand.inkGradient) : AnyShapeStyle(.ultraThinMaterial), in: Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("New Collage")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { onCreate(template, aspect); dismiss() }
                }
            }
        }
    }
}

#Preview {
    ProjectsView().modelContainer(for: CollageProject.self, inMemory: true)
}
