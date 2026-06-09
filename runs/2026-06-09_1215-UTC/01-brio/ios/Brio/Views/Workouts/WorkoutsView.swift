import SwiftUI
import SwiftData

struct WorkoutsView: View {
    @Query(sort: [SortDescriptor(\Workout.sortIndex), SortDescriptor(\Workout.createdAt, order: .reverse)])
    private var workouts: [Workout]

    @State private var filter: WorkoutCategory? = nil

    private var filtered: [Workout] {
        guard let filter else { return workouts }
        return workouts.filter { $0.category == filter }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    filterBar

                    if workouts.isEmpty {
                        EmptyStateView(icon: "figure.run",
                                       title: "No workouts yet",
                                       message: "Head to the Build tab to create your first session, or restart the app to restore the built-ins.")
                            .glassCard()
                    } else if filtered.isEmpty {
                        EmptyStateView(icon: "line.3.horizontal.decrease.circle",
                                       title: "Nothing in this category",
                                       message: "Try another category or build a new workout.")
                            .glassCard()
                    } else {
                        LazyVStack(spacing: 14) {
                            ForEach(filtered) { workout in
                                NavigationLink {
                                    WorkoutDetailView(workout: workout)
                                } label: {
                                    WorkoutCard(workout: workout)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background(Brand.pageBackground)
            .navigationTitle("Workouts")
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterPill(title: "All", isOn: filter == nil) {
                    Haptics.selection(); filter = nil
                }
                ForEach(WorkoutCategory.allCases) { cat in
                    FilterPill(title: cat.label, isOn: filter == cat, tint: cat.tint) {
                        Haptics.selection()
                        filter = (filter == cat) ? nil : cat
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }
}

private struct FilterPill: View {
    let title: String
    let isOn: Bool
    var tint: Color = Brand.text
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(isOn ? .white : Brand.text)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isOn ? tint : Brand.hairline.opacity(0.4), in: Capsule())
                .overlay(
                    Capsule().strokeBorder(Brand.glassStroke.opacity(0.5), lineWidth: isOn ? 0 : 1)
                )
        }
        .accessibilityAddTraits(isOn ? [.isSelected] : [])
    }
}

struct WorkoutCard: View {
    let workout: Workout

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: workout.category.symbol)
                    .font(.title2)
                    .foregroundStyle(workout.category.tint)
                    .frame(width: 44, height: 44)
                    .background(workout.category.tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text(workout.name)
                        .font(.headline)
                        .foregroundStyle(Brand.text)
                    Text(workout.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(Brand.text2)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Brand.text3)
                    .accessibilityHidden(true)
            }

            HStack(spacing: 8) {
                TagChip(text: workout.category.label, systemImage: workout.category.symbol, tint: workout.category.tint)
                TagChip(text: workout.difficulty.label, tint: workout.difficulty.tint)
                if !workout.isBuiltIn {
                    TagChip(text: "Custom", systemImage: "person.fill", tint: Brand.info)
                }
            }
        }
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(workout.name), \(workout.category.label), \(workout.difficulty.label)")
        .accessibilityHint("Opens workout details")
    }
}
