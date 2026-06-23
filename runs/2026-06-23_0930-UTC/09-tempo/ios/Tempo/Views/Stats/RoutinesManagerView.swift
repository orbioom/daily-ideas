import SwiftUI
import SwiftData

/// Full CRUD list of routine templates.
struct RoutinesManagerView: View {
    let prefs: AppSettings
    @Environment(\.modelContext) private var context
    @Query(sort: \Routine.createdAt) private var routines: [Routine]

    @State private var editorRoutine: Routine?
    @State private var showNew = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            if routines.isEmpty {
                ContentUnavailableView {
                    Label("No routines", systemImage: "rectangle.stack")
                } description: {
                    Text("Create reusable templates to start workouts in one tap.")
                } actions: {
                    Button("New Routine") { showNew = true }.buttonStyle(.borderedProminent)
                }
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(routines) { routine in
                            Button { editorRoutine = routine } label: {
                                RoutineManagerRow(routine: routine)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(role: .destructive) { delete(routine) } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(16)
                }
            }
        }
        .navigationTitle("Routines")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showNew = true } label: { Image(systemName: "plus") }
                    .accessibilityLabel("New routine")
            }
        }
        .sheet(isPresented: $showNew) {
            RoutineEditorView()
        }
        .sheet(item: $editorRoutine) { routine in
            RoutineEditorView(existing: routine)
        }
    }

    private func delete(_ routine: Routine) {
        context.delete(routine)
        try? context.save()
        Haptics.impact(.rigid, enabled: prefs.hapticsEnabled)
    }
}

struct RoutineManagerRow: View {
    let routine: Routine
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8).fill(Color(hex: routine.colorHex))
                .frame(width: 6, height: 44).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(routine.name).font(.headline).foregroundStyle(Theme.textPrimary)
                    if routine.isBuiltIn {
                        TagPill(text: "Starter", tint: Theme.textSecondary)
                    }
                }
                Text("\(routine.items.count) exercises").font(.caption).foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(Theme.textSecondary)
                .accessibilityHidden(true)
        }
        .cardSurface()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(routine.name), \(routine.items.count) exercises")
        .accessibilityHint("Opens routine editor")
    }
}
