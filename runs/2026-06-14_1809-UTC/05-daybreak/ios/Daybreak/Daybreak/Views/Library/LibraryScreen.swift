import SwiftUI
import SwiftData

/// Routines library: reorderable list, CRUD, plus entry points to the editor and templates.
struct LibraryScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false

    @Query(sort: \Routine.sortOrder) private var routines: [Routine]

    @State private var editorTarget: RoutineEditorTarget?
    @State private var showTemplates = false
    @State private var paywallReason: PaywallReason?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if routines.isEmpty {
                    EmptyStateView(symbol: "list.bullet.rectangle",
                                   title: "No routines yet",
                                   message: "Build a routine from scratch or start with a ready-made template.",
                                   actionTitle: "Browse templates") { showTemplates = true }
                        .padding(.horizontal, 8)
                } else {
                    list
                }
            }
            .navigationTitle("Routines")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showTemplates = true } label: {
                        Label("Templates", systemImage: "square.grid.2x2")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { addRoutine() } label: {
                        Label("New routine", systemImage: "plus")
                    }
                }
                if !routines.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        EditButton()
                    }
                }
            }
            .sheet(item: $editorTarget) { target in
                RoutineEditorView(target: target)
            }
            .sheet(isPresented: $showTemplates) {
                TemplatesGalleryView(onCreate: createFromTemplate(_:))
            }
            .sheet(item: $paywallReason) { reason in
                PaywallView(reason: reason)
            }
        }
    }

    private var list: some View {
        List {
            ForEach(routines) { routine in
                Button {
                    editorTarget = .edit(routine)
                } label: {
                    RoutineRow(routine: routine)
                }
                .listRowBackground(Theme.surface)
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) { delete(routine) } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            .onMove(perform: move)
            .onDelete(perform: deleteAt)

            if !isPro {
                Section {
                    HStack {
                        Image(systemName: "infinity")
                            .foregroundStyle(Theme.accent)
                            .accessibilityHidden(true)
                        Text("\(routines.count) of \(Pro.freeRoutineLimit) free routines used")
                            .font(Theme.rounded(13))
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
                .listRowBackground(Theme.surfaceAlt)
            }
        }
        .scrollContentBackground(.hidden)
    }

    // MARK: Actions

    private func addRoutine() {
        guard Pro.canAddRoutine(currentCount: routines.count, isPro: isPro) else {
            paywallReason = .routineLimit
            return
        }
        Haptics.tap(settings.hapticsEnabled)
        editorTarget = .create(nextSortOrder: nextSortOrder)
    }

    private func createFromTemplate(_ template: RoutineTemplate) {
        if (template.isPro && !isPro) || !Pro.canAddRoutine(currentCount: routines.count, isPro: isPro) {
            showTemplates = false
            paywallReason = .routineLimit
            return
        }
        let routine = template.makeRoutine(sortOrder: nextSortOrder)
        context.insert(routine)
        try? context.save()
        Haptics.success(settings.hapticsEnabled)
        showTemplates = false
    }

    private var nextSortOrder: Int {
        (routines.map(\.sortOrder).max() ?? -1) + 1
    }

    private func delete(_ routine: Routine) {
        context.delete(routine)
        try? context.save()
        Haptics.warning(settings.hapticsEnabled)
    }

    private func deleteAt(_ offsets: IndexSet) {
        for index in offsets where routines.indices.contains(index) {
            context.delete(routines[index])
        }
        try? context.save()
    }

    private func move(_ offsets: IndexSet, _ destination: Int) {
        var reordered = routines
        reordered.move(fromOffsets: offsets, toOffset: destination)
        for (i, routine) in reordered.enumerated() {
            routine.sortOrder = i
        }
        try? context.save()
    }
}

/// A compact row in the routines list.
private struct RoutineRow: View {
    let routine: Routine

    private var accent: Color { Color(hex: parseHex(routine.colorHex)) }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(accent.opacity(0.18))
                    .frame(width: 42, height: 42)
                Image(systemName: routine.iconName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(accent)
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(routine.name)
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.ink)
                HStack(spacing: 6) {
                    Image(systemName: routine.timeOfDay.symbol)
                        .accessibilityHidden(true)
                    Text(routine.timeOfDay.label)
                    Text("·")
                    Text("\(routine.orderedSteps.count) steps · \(TimeFormat.minutesLabel(routine.estimatedMinutes))")
                }
                .font(Theme.rounded(12))
                .foregroundStyle(Theme.inkSoft)
            }
            Spacer()
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}
