import SwiftUI
import SwiftData

/// A searchable, filterable picker for adding an exercise to a workout or routine.
struct ExercisePickerSheet: View {
    let onPick: (Exercise) -> Void
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var exercises: [Exercise]

    @State private var query = ""
    @State private var muscleFilter: MuscleGroup?

    private var filtered: [Exercise] {
        exercises.filter { ex in
            (muscleFilter == nil || ex.muscle == muscleFilter) &&
            (query.isEmpty || ex.name.localizedCaseInsensitiveContains(query))
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                VStack(spacing: 0) {
                    filterBar
                    if filtered.isEmpty {
                        ContentUnavailableView {
                            Label("No matches", systemImage: "magnifyingglass")
                        } description: {
                            Text("Try a different search or filter.")
                        }
                    } else {
                        List {
                            ForEach(filtered) { ex in
                                Button {
                                    onPick(ex)
                                    dismiss()
                                } label: {
                                    ExercisePickerRow(exercise: ex)
                                }
                                .listRowBackground(Theme.card)
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: "Search lifts")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(nil, "All")
                ForEach(MuscleGroup.allCases) { m in
                    filterChip(m, m.display)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    private func filterChip(_ muscle: MuscleGroup?, _ title: String) -> some View {
        let selected = muscleFilter == muscle
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                muscleFilter = selected ? nil : muscle
            }
        } label: {
            Text(title)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(selected ? Theme.accent : Theme.card, in: Capsule())
                .foregroundStyle(selected ? .white : Theme.textPrimary)
                .overlay(Capsule().strokeBorder(Theme.cardStroke, lineWidth: selected ? 0 : 1))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

struct ExercisePickerRow: View {
    let exercise: Exercise
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: exercise.muscle.symbol)
                .foregroundStyle(Theme.accent)
                .frame(width: 26)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name).font(.body.weight(.medium)).foregroundStyle(Theme.textPrimary)
                Text("\(exercise.muscle.display) · \(exercise.equipment.display)")
                    .font(.caption).foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            if exercise.isFavorite {
                Image(systemName: "star.fill").font(.caption).foregroundStyle(Theme.pr)
                    .accessibilityLabel("Favorite")
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }
}
