import SwiftUI
import SwiftData

struct WorkoutListView: View {
    @Query(sort: \RowWorkout.date, order: .reverse) private var workouts: [RowWorkout]
    @Query private var settings: [StrokeSettings]
    @Environment(\.modelContext) private var context
    @State private var showLog = false
    @State private var selected: RowWorkout? = nil
    @State private var filterType: WorkoutType? = nil

    private var displayWatts: Bool { settings.first?.displayWatts ?? false }

    private var filtered: [RowWorkout] {
        guard let t = filterType else { return workouts }
        return workouts.filter { $0.workoutType == t }
    }

    private var grouped: [(String, [RowWorkout])] {
        let fmt = DateFormatter(); fmt.dateFormat = "MMMM yyyy"
        let dict = Dictionary(grouping: filtered) { fmt.string(from: $0.date) }
        return dict.sorted { a, b in
            let ad = filtered.first { fmt.string(from: $0.date) == a.key }?.date ?? .distantPast
            let bd = filtered.first { fmt.string(from: $0.date) == b.key }?.date ?? .distantPast
            return ad > bd
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if workouts.isEmpty {
                    emptyState
                } else {
                    List {
                        filterRow
                            .listRowBackground(Color.clear)
                            .listRowInsets(.init())
                        ForEach(grouped, id: \.0) { month, items in
                            Section(header: Text(month)) {
                                ForEach(items) { w in
                                    WorkoutRowView(workout: w, displayWatts: displayWatts)
                                        .contentShape(Rectangle())
                                        .onTapGesture { selected = w }
                                        .swipeActions(edge: .trailing) {
                                            Button(role: .destructive) {
                                                context.delete(w)
                                            } label: { Label("Delete", systemImage: "trash") }
                                        }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Workouts")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showLog = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showLog) { LogWorkoutView() }
            .sheet(item: $selected) { w in
                WorkoutDetailView(workout: w, displayWatts: displayWatts)
            }
        }
    }

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip("All", selected: filterType == nil) { filterType = nil }
                ForEach(WorkoutType.allCases, id: \.self) { t in
                    filterChip(t.rawValue, selected: filterType == t) {
                        filterType = filterType == t ? nil : t
                    }
                }
            }
            .padding(.horizontal).padding(.vertical, 6)
        }
    }

    private func filterChip(_ label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.caption.bold())
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(selected ? Color.accentColor : Color(.secondarySystemBackground))
                .foregroundStyle(selected ? .white : .primary)
                .clipShape(Capsule())
        }
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.rowing")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text("No workouts yet")
                .font(.title3.bold())
            Text("Tap + to log your first piece")
                .foregroundStyle(.secondary)
            Button("Log Workout") { showLog = true }
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

struct WorkoutRowView: View {
    let workout: RowWorkout
    let displayWatts: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: workout.workoutType.icon)
                .font(.title2)
                .foregroundStyle(.teal)
                .frame(width: 32)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(workout.workoutType.rawValue)
                    .font(.subheadline.bold())
                Text(workout.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(workout.distanceDisplay)
                    .font(.subheadline.bold())
                HStack(spacing: 6) {
                    Text(workout.split500mDisplay + "/500m")
                    if displayWatts && workout.avgWatts > 0 {
                        Text(String(format: "%.0fW", workout.avgWatts))
                    }
                }
                .font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }
}
