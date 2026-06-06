import SwiftUI
import SwiftData

/// The routine library: every saved routine as a glass card, with create / run entry
/// points. The home of the app's value-based navigation stack.
struct LibraryView: View {
    @Environment(\.modelContext) private var context
    @Environment(SettingsStore.self) private var settings
    @Query(sort: \Routine.createdAt, order: .reverse) private var routines: [Routine]

    @State private var path: [LibraryRoute] = []
    @State private var editingRoutine: Routine?
    @State private var runningRoutine: Routine?
    @State private var pendingDelete: Routine?

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Brand.pageBackground

                if routines.isEmpty {
                    EmptyStateView(
                        icon: "list.bullet.rectangle.portrait",
                        title: "Build your first routine",
                        message: "A routine is a sequence of segments — prepare, work, rest, cooldown — that Interval runs for you.",
                        actionTitle: "New routine",
                        action: { editingRoutine = makeDraft() }
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            ForEach(routines) { routine in
                                Button {
                                    path.append(.detail(routine.id))
                                } label: {
                                    RoutineCard(routine: routine)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button {
                                        runningRoutine = routine
                                    } label: { Label("Run", systemImage: "play.fill") }
                                        .disabled(!routine.isRunnable)
                                    Button {
                                        editingRoutine = routine
                                    } label: { Label("Edit", systemImage: "slider.horizontal.3") }
                                    Button(role: .destructive) {
                                        pendingDelete = routine
                                    } label: { Label("Delete", systemImage: "trash") }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Routines")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        editingRoutine = makeDraft()
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("New routine")
                }
            }
            .navigationDestination(for: LibraryRoute.self) { route in
                destination(for: route)
            }
        }
        .sheet(item: $editingRoutine) { routine in
            BuilderView(routine: routine)
        }
        .fullScreenCover(item: $runningRoutine) { routine in
            RunView(routine: routine)
        }
        .alert("Delete routine?",
               isPresented: Binding(get: { pendingDelete != nil },
                                    set: { if !$0 { pendingDelete = nil } })) {
            Button("Cancel", role: .cancel) { pendingDelete = nil }
            Button("Delete", role: .destructive) {
                if let routine = pendingDelete { delete(routine) }
                pendingDelete = nil
            }
        } message: {
            Text("This removes the routine and its run history. This can't be undone.")
        }
    }

    @ViewBuilder
    private func destination(for route: LibraryRoute) -> some View {
        switch route {
        case .detail(let id):
            if let routine = routines.first(where: { $0.id == id }) {
                RoutineDetailView(routine: routine,
                                  onEdit: { editingRoutine = routine },
                                  onRun: { runningRoutine = routine })
            } else {
                // The routine was deleted while its detail was on the stack.
                EmptyStateView(icon: "questionmark.folder",
                               title: "Routine unavailable",
                               message: "This routine is no longer in your library.")
            }
        }
    }

    /// A blank, unsaved routine the builder fills in. Inserted only when saved.
    private func makeDraft() -> Routine {
        Routine(name: "")
    }

    private func delete(_ routine: Routine) {
        context.delete(routine)
        try? context.save()
        Haptics.warning(enabled: settings.hapticsEnabled)
    }
}

/// Value-based routes for the library stack.
enum LibraryRoute: Hashable {
    case detail(UUID)
}

#Preview {
    LibraryView().intervalPreview()
}
