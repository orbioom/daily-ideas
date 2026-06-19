import SwiftUI

struct ExerciseLibraryView: View {
    @State private var selectedCategory: ExerciseCategory? = nil
    @State private var selectedExercise: Exercise? = nil
    @State private var searchText = ""

    private var filtered: [Exercise] {
        let pool = selectedCategory.map { ExerciseLibrary.all.filter { $0.category == $1 } } ?? ExerciseLibrary.all
        if searchText.isEmpty { return pool }
        return pool.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.category.rawValue.localizedCaseInsensitiveContains(searchText)
        }
    }

    private func exercises(for category: ExerciseCategory) -> [Exercise] {
        filtered.filter { $0.category == category }
    }

    private var visibleCategories: [ExerciseCategory] {
        ExerciseCategory.allCases.filter { exercises(for: $0).count > 0 }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Category filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            categoryChip(label: "All", category: nil)
                            ForEach(ExerciseCategory.allCases) { cat in
                                categoryChip(label: cat.rawValue, category: cat)
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    // Exercise groups
                    ForEach(visibleCategories) { category in
                        categorySection(category: category)
                    }
                }
                .padding(.bottom, 24)
            }
            .searchable(text: $searchText, prompt: "Search exercises")
            .navigationTitle("Exercises")
            .background(PoiseTheme.backgroundSecondary)
            .sheet(item: $selectedExercise) { exercise in
                ExerciseDetailView(exercise: exercise)
            }
        }
    }

    private func categoryChip(label: String, category: ExerciseCategory?) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedCategory = category
            }
        } label: {
            HStack(spacing: 6) {
                if let cat = category {
                    Image(systemName: cat.icon)
                        .font(.caption)
                }
                Text(label)
                    .font(.subheadline.weight(.medium))
            }
            .foregroundColor(selectedCategory == category ? .white : PoiseTheme.textPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(selectedCategory == category ? PoiseTheme.sky : PoiseTheme.cardBackground)
            .clipShape(Capsule())
        }
    }

    private func categorySection(category: ExerciseCategory) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                    .foregroundColor(PoiseTheme.categoryColor(for: category))
                Text(category.rawValue)
                    .font(.headline)
                    .foregroundColor(PoiseTheme.textPrimary)
                Spacer()
                Text("\(exercises(for: category).count) exercises")
                    .font(.caption)
                    .foregroundColor(PoiseTheme.textMuted)
            }
            .padding(.horizontal, 20)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(exercises(for: category)) { exercise in
                    ExerciseCardView(exercise: exercise)
                        .onTapGesture {
                            selectedExercise = exercise
                        }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

struct ExerciseCardView: View {
    let exercise: Exercise

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: exercise.sfSymbol)
                    .foregroundColor(PoiseTheme.categoryColor(for: exercise.category))
                    .font(.title3)
                    .frame(width: 40, height: 40)
                    .background(PoiseTheme.categoryColor(for: exercise.category).opacity(0.12))
                    .clipShape(Circle())
                Spacer()
                Text("\(exercise.durationSeconds)s")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(PoiseTheme.textMuted)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(PoiseTheme.backgroundTertiary)
                    .clipShape(Capsule())
            }
            Text(exercise.name)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(PoiseTheme.textPrimary)
                .lineLimit(2)
            Text(exercise.benefits)
                .font(.caption)
                .foregroundColor(PoiseTheme.textSecondary)
                .lineLimit(2)
        }
        .padding(14)
        .background(PoiseTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct ExerciseDetailView: View {
    let exercise: Exercise
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Hero
                    VStack(spacing: 16) {
                        Image(systemName: exercise.sfSymbol)
                            .font(.system(size: 56))
                            .foregroundColor(PoiseTheme.categoryColor(for: exercise.category))
                            .frame(width: 100, height: 100)
                            .background(PoiseTheme.categoryColor(for: exercise.category).opacity(0.12))
                            .clipShape(Circle())

                        Text(exercise.name)
                            .font(.title2.weight(.bold))
                            .foregroundColor(PoiseTheme.textPrimary)
                            .multilineTextAlignment(.center)

                        HStack(spacing: 16) {
                            Label(exercise.category.rawValue, systemImage: exercise.category.icon)
                                .font(.caption)
                                .foregroundColor(PoiseTheme.categoryColor(for: exercise.category))
                            Label("\(exercise.durationSeconds) seconds", systemImage: "clock")
                                .font(.caption)
                                .foregroundColor(PoiseTheme.textSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)

                    sectionCard(title: "Instructions", icon: "text.alignleft") {
                        Text(exercise.instruction)
                            .font(.body)
                            .foregroundColor(PoiseTheme.textPrimary)
                            .lineSpacing(4)
                    }

                    sectionCard(title: "Step by Step", icon: "list.number") {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(Array(exercise.steps.enumerated()), id: \.offset) { index, step in
                                HStack(alignment: .top, spacing: 12) {
                                    Text("\(index + 1)")
                                        .font(.caption.weight(.bold))
                                        .foregroundColor(.white)
                                        .frame(width: 24, height: 24)
                                        .background(PoiseTheme.sky)
                                        .clipShape(Circle())
                                    Text(step)
                                        .font(.subheadline)
                                        .foregroundColor(PoiseTheme.textPrimary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }

                    sectionCard(title: "Benefits", icon: "heart.fill") {
                        Text(exercise.benefits)
                            .font(.subheadline)
                            .foregroundColor(PoiseTheme.textPrimary)
                            .lineSpacing(4)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .background(PoiseTheme.backgroundSecondary)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func sectionCard<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundColor(PoiseTheme.textPrimary)

            content()
        }
        .padding(18)
        .background(PoiseTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
