import SwiftUI
import SwiftData

/// Lists the user's custom workouts with full CRUD and an entry point to create
/// a new one. Built-in workouts live in the Workouts tab; this tab is for the
/// ones you make.
struct BuilderListView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<Workout> { !$0.isBuiltIn },
           sort: \Workout.createdAt, order: .reverse)
    private var customWorkouts: [Workout]

    @State private var editing: Workout?
    @State private var creatingNew = false
    @State private var pendingDelete: Workout?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Build a session from the move library — set reps or time, rounds, and rest, then save it to your Workouts.")
                        .font(.subheadline)
                        .foregroundStyle(Brand.text2)

                    if customWorkouts.isEmpty {
                        EmptyStateView(icon: "hammer",
                                       title: "No custom workouts yet",
                                       message: "Tap New workout to design your first one. It'll appear here and in Workouts.")
                            .glassCard()
                    } else {
                        LazyVStack(spacing: 14) {
                            ForEach(customWorkouts) { workout in
                                Button {
                                    Haptics.tap()
                                    editing = workout
                                } label: {
                                    WorkoutCard(workout: workout)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        pendingDelete = workout
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(20)
                .padding(.bottom, 80)
            }
            .background(Brand.pageBackground)
            .navigationTitle("Build")
            .safeAreaInset(edge: .bottom) {
                Button {
                    Haptics.tap()
                    creatingNew = true
                } label: {
                    Label("New workout", systemImage: "plus")
                }
                .buttonStyle(InkButtonStyle())
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
            }
            .sheet(isPresented: $creatingNew) {
                WorkoutEditorView(mode: .create)
            }
            .sheet(item: $editing) { workout in
                WorkoutEditorView(mode: .edit(workout))
            }
            .confirmationDialog("Delete this workout?",
                                isPresented: Binding(get: { pendingDelete != nil },
                                                     set: { if !$0 { pendingDelete = nil } }),
                                titleVisibility: .visible,
                                presenting: pendingDelete) { workout in
                Button("Delete", role: .destructive) {
                    context.delete(workout)
                    try? context.save()
                    Haptics.warning()
                    pendingDelete = nil
                }
                Button("Cancel", role: .cancel) { pendingDelete = nil }
            } message: { workout in
                Text("\"\(workout.name)\" will be permanently removed. Logged sessions are kept.")
            }
        }
    }
}
