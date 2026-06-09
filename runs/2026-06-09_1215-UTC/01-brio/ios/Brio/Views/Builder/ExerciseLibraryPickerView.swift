import SwiftUI
import SwiftData

/// A searchable, filterable picker over the exercise library. Tapping an
/// exercise calls `onPick` and dismisses.
struct ExerciseLibraryPickerView: View {
    let onPick: (Exercise) -> Void

    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var exercises: [Exercise]

    @State private var search = ""
    @State private var group: MuscleGroup? = nil

    private var filtered: [Exercise] {
        exercises.filter { ex in
            let matchesGroup = group == nil || ex.muscleGroup == group
            let matchesSearch = search.isEmpty ||
                ex.name.localizedCaseInsensitiveContains(search)
            return matchesGroup && matchesSearch
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    groupBar

                    if exercises.isEmpty {
                        EmptyStateView(icon: "dumbbell",
                                       title: "Library is empty",
                                       message: "Restart the app to restore the built-in exercises.")
                            .glassCard()
                    } else if filtered.isEmpty {
                        EmptyStateView(icon: "magnifyingglass",
                                       title: "No matches",
                                       message: "Try a different search or muscle group.")
                            .glassCard()
                    } else {
                        LazyVStack(spacing: 10) {
                            ForEach(filtered) { exercise in
                                Button {
                                    onPick(exercise)
                                    dismiss()
                                } label: {
                                    ExerciseRow(exercise: exercise)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background(Brand.pageBackground)
            .navigationTitle("Add a move")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $search, prompt: "Search exercises")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var groupBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                groupPill(title: "All", isOn: group == nil) { group = nil }
                ForEach(MuscleGroup.allCases) { g in
                    groupPill(title: g.label, isOn: group == g) {
                        group = (group == g) ? nil : g
                    }
                }
            }
        }
    }

    private func groupPill(title: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.selection()
            action()
        } label: {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(isOn ? .white : Brand.text)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isOn ? Brand.magic : Brand.hairline.opacity(0.4), in: Capsule())
        }
        .accessibilityAddTraits(isOn ? [.isSelected] : [])
    }
}

private struct ExerciseRow: View {
    let exercise: Exercise

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: exercise.symbol)
                .font(.title3)
                .foregroundStyle(Brand.magic)
                .frame(width: 40, height: 40)
                .background(Brand.magic.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(exercise.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Brand.text)
                Text(exercise.detail)
                    .font(.caption)
                    .foregroundStyle(Brand.text2)
                    .lineLimit(2)
            }
            Spacer(minLength: 6)
            VStack(alignment: .trailing, spacing: 4) {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(Brand.magic)
                    .accessibilityHidden(true)
                Text(exercise.kind.label)
                    .font(Brand.mono(10, weight: .medium))
                    .foregroundStyle(Brand.text3)
            }
        }
        .glassCard(padding: 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(exercise.name), \(exercise.muscleGroup.label)")
        .accessibilityHint("Adds this move to the workout")
    }
}
