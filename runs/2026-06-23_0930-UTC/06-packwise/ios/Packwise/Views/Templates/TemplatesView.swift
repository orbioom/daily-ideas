import SwiftUI
import SwiftData

/// Screen 4 — reusable templates: browse, create, edit, delete.
struct TemplatesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Template.name) private var templates: [Template]

    @State private var showingNew = false
    @State private var templateToDelete: Template?

    private var builtIns: [Template] { templates.filter(\.isBuiltIn) }
    private var custom: [Template] { templates.filter { !$0.isBuiltIn } }

    var body: some View {
        NavigationStack {
            Group {
                if templates.isEmpty {
                    EmptyStateView(
                        symbol: "square.stack.3d.up",
                        title: "No templates",
                        message: "Templates are reusable item lists you can drop into any trip.",
                        actionTitle: "Create a template",
                        action: { showingNew = true }
                    )
                } else {
                    list
                }
            }
            .background(Theme.background)
            .navigationTitle("Templates")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingNew = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Create a template")
                }
            }
            .navigationDestination(for: Template.self) { template in
                TemplateEditorView(template: template)
            }
            .sheet(isPresented: $showingNew) {
                NewTemplateSheet()
            }
            .confirmationDialog(
                "Delete this template?",
                isPresented: Binding(
                    get: { templateToDelete != nil },
                    set: { if !$0 { templateToDelete = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let t = templateToDelete { delete(t) }
                    templateToDelete = nil
                }
                Button("Cancel", role: .cancel) { templateToDelete = nil }
            }
        }
    }

    private var list: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Theme.Space.lg) {
                if !builtIns.isEmpty {
                    header("Starter templates")
                    ForEach(builtIns) { template in
                        NavigationLink(value: template) {
                            TemplateCard(template: template)
                        }
                        .buttonStyle(.plain)
                    }
                }
                header(custom.isEmpty ? "Your templates" : "Your templates")
                if custom.isEmpty {
                    Text("Tap + to save your own reusable list.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                        .padding(.horizontal, Theme.Space.xs)
                } else {
                    ForEach(custom) { template in
                        NavigationLink(value: template) {
                            TemplateCard(template: template)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) {
                                templateToDelete = template
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .padding(Theme.Space.lg)
        }
    }

    private func header(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(Theme.textSecondary)
    }

    private func delete(_ template: Template) {
        context.delete(template)
        try? context.save()
    }
}

private struct TemplateCard: View {
    let template: Template
    var body: some View {
        HStack(spacing: Theme.Space.md) {
            IconBadge(symbol: template.symbol, tint: Theme.primary, size: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(template.name)
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                if !template.detail.isEmpty {
                    Text(template.detail)
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                }
                Text("\(template.itemCount) items")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            if template.isBuiltIn {
                Text("Starter")
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, Theme.Space.sm)
                    .padding(.vertical, 3)
                    .background(Theme.primary.opacity(0.15))
                    .foregroundStyle(Theme.primary)
                    .clipShape(Capsule())
            }
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(Theme.textSecondary)
                .accessibilityHidden(true)
        }
        .card()
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens template")
    }
}
