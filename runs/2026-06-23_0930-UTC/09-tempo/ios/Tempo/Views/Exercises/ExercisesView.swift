import SwiftUI
import SwiftData

/// Exercises tab — the library. Search, filter, favorite, and create custom lifts.
struct ExercisesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @Query private var settings: [AppSettings]

    @State private var query = ""
    @State private var muscleFilter: MuscleGroup?
    @State private var favoritesOnly = false
    @State private var showEditor = false

    private var prefs: AppSettings { SettingsAccess.current(settings, context: context) }

    private var filtered: [Exercise] {
        exercises.filter { ex in
            (muscleFilter == nil || ex.muscle == muscleFilter) &&
            (!favoritesOnly || ex.isFavorite) &&
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
                        emptyState
                    } else {
                        List {
                            ForEach(filtered) { ex in
                                NavigationLink(value: ex.id) {
                                    ExercisePickerRow(exercise: ex)
                                }
                                .listRowBackground(Theme.card)
                                .swipeActions(edge: .leading) {
                                    Button { toggleFavorite(ex) } label: {
                                        Label("Favorite", systemImage: ex.isFavorite ? "star.slash" : "star")
                                    }
                                    .tint(Theme.pr)
                                }
                                .swipeActions(edge: .trailing) {
                                    if ex.isCustom {
                                        Button(role: .destructive) { deleteExercise(ex) } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("Exercises")
            .searchable(text: $query, prompt: "Search lifts")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showEditor = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Create exercise")
                }
            }
            .navigationDestination(for: UUID.self) { id in
                if let ex = exercises.first(where: { $0.id == id }) {
                    ExerciseDetailView(exercise: ex, prefs: prefs)
                } else {
                    ContentUnavailableView("Exercise removed", systemImage: "trash")
                }
            }
            .sheet(isPresented: $showEditor) {
                ExerciseEditorView()
            }
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(selected: favoritesOnly, title: "Favorites", icon: "star.fill") {
                    favoritesOnly.toggle()
                }
                chip(selected: muscleFilter == nil && !favoritesOnly, title: "All", icon: nil) {
                    muscleFilter = nil; favoritesOnly = false
                }
                ForEach(MuscleGroup.allCases) { m in
                    chip(selected: muscleFilter == m, title: m.display, icon: nil) {
                        muscleFilter = muscleFilter == m ? nil : m
                    }
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 10)
        }
    }

    private func chip(selected: Bool, title: String, icon: String?, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) { action() }
        } label: {
            HStack(spacing: 4) {
                if let icon { Image(systemName: icon).imageScale(.small) }
                Text(title)
            }
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 14).padding(.vertical, 7)
            .background(selected ? Theme.accent : Theme.card, in: Capsule())
            .foregroundStyle(selected ? .white : Theme.textPrimary)
            .overlay(Capsule().strokeBorder(Theme.cardStroke, lineWidth: selected ? 0 : 1))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No exercises", systemImage: "magnifyingglass")
        } description: {
            Text(favoritesOnly ? "You haven't favorited any lifts yet." : "Try a different search or filter, or create a custom lift.")
        } actions: {
            Button("Create Exercise") { showEditor = true }
                .buttonStyle(.borderedProminent)
        }
    }

    private func toggleFavorite(_ ex: Exercise) {
        ex.isFavorite.toggle()
        try? context.save()
        Haptics.selection(enabled: prefs.hapticsEnabled)
    }

    private func deleteExercise(_ ex: Exercise) {
        context.delete(ex)
        try? context.save()
        Haptics.impact(.rigid, enabled: prefs.hapticsEnabled)
    }
}

#Preview {
    ExercisesView().modelContainer(PersistenceController.preview)
}
