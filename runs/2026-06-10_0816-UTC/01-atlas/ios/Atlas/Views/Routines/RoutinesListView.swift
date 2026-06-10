import SwiftUI
import SwiftData

struct RoutinesListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Routine.orderIndex) private var routines: [Routine]
    @State private var showEditor = false
    @State private var deleteTarget: Routine?

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if routines.isEmpty {
                    VStack(spacing: 16) {
                        EmptyStateView(
                            icon: "list.bullet.rectangle.portrait",
                            title: "No routines yet",
                            message: "A routine is a reusable workout template. Build your own, or install the starter program."
                        )
                        Button {
                            StarterProgram.install(into: context)
                            Haptics.success()
                        } label: {
                            Label("Install starter program", systemImage: "square.stack.3d.up")
                        }
                        .buttonStyle(GlassButtonStyle())
                        .padding(.horizontal, 48)
                    }
                } else {
                    List {
                        ForEach(routines) { routine in
                            NavigationLink(value: routine) {
                                RoutineRow(routine: routine)
                            }
                            .listRowBackground(Color.clear)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    deleteTarget = routine
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Routines")
            .navigationDestination(for: Routine.self) { RoutineDetailView(routine: $0) }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("New routine")
                }
            }
            .sheet(isPresented: $showEditor) {
                RoutineEditorView(routine: nil)
            }
            .alert("Delete this routine?", isPresented: Binding(
                get: { deleteTarget != nil },
                set: { if !$0 { deleteTarget = nil } }
            )) {
                Button("Delete", role: .destructive) {
                    if let r = deleteTarget {
                        context.delete(r)
                        Haptics.warning()
                    }
                    deleteTarget = nil
                }
                Button("Cancel", role: .cancel) { deleteTarget = nil }
            } message: {
                Text("Logged workouts are kept — only the template is removed.")
            }
        }
    }
}

private struct RoutineRow: View {
    let routine: Routine

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(routine.name)
                .font(.headline)
                .foregroundStyle(Brand.text)
            HStack(spacing: 10) {
                Text("\(routine.exercises.count) exercises")
                    .font(.subheadline)
                    .foregroundStyle(Brand.text2)
                HStack(spacing: 4) {
                    ForEach(muscles, id: \.self) { m in
                        Image(systemName: m.symbol)
                            .font(.caption)
                            .foregroundStyle(Brand.text3)
                    }
                }
                .accessibilityLabel(muscles.map(\.label).joined(separator: ", "))
            }
        }
        .padding(.vertical, 6)
    }

    private var muscles: [Muscle] {
        var seen: Set<Muscle> = []
        return routine.orderedExercises.compactMap { ex in
            seen.insert(ex.muscle).inserted ? ex.muscle : nil
        }
    }
}
