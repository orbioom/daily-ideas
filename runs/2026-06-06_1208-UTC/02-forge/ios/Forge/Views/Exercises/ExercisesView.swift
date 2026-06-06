import SwiftUI
import SwiftData

/// The lift catalog, grouped by muscle group.
struct ExercisesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Exercise.name) private var exercises: [Exercise]

    @State private var search = ""
    @State private var addingExercise = false

    private var filtered: [Exercise] {
        search.isEmpty ? exercises
            : exercises.filter { $0.name.localizedCaseInsensitiveContains(search) }
    }
    private var grouped: [(MuscleGroup, [Exercise])] {
        MuscleGroup.allCases.compactMap { g in
            let items = filtered.filter { $0.group == g }
            return items.isEmpty ? nil : (g, items)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Group {
                    if exercises.isEmpty {
                        EmptyStateView(icon: "list.bullet.rectangle",
                                       title: "No lifts yet",
                                       message: "Add the movements you train, or they'll be created as you log sets.")
                    } else if filtered.isEmpty {
                        EmptyStateView(icon: "magnifyingglass", title: "No matches",
                                       message: "No lift matches your search.")
                    } else { list }
                }
            }
            .navigationTitle("Lifts")
            .searchable(text: $search, prompt: "Search lifts")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { addingExercise = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("New lift")
                }
            }
            .navigationDestination(for: Exercise.self) { ExerciseDetailView(exercise: $0) }
            .sheet(isPresented: $addingExercise) { ExerciseEditView() }
        }
    }

    private var list: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                ForEach(grouped, id: \.0) { group, items in
                    VStack(alignment: .leading, spacing: 10) {
                        Eyebrow(text: group.label)
                        ForEach(items) { ex in
                            NavigationLink(value: ex) {
                                HStack(spacing: 12) {
                                    Image(systemName: ex.group.symbol).foregroundStyle(Brand.text2)
                                        .frame(width: 28)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(ex.name).font(.headline).foregroundStyle(Brand.text)
                                        if ex.isBodyweight {
                                            Text("Bodyweight").font(.caption).foregroundStyle(Brand.text3)
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right").font(.footnote).foregroundStyle(Brand.text3)
                                }
                                .glassCard()
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(role: .destructive) { delete(ex) } label: { Label("Delete", systemImage: "trash") }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16).padding(.bottom, 28)
        }
    }

    private func delete(_ ex: Exercise) { context.delete(ex); try? context.save(); Haptics.warning() }
}

/// Create or edit a lift definition.
struct ExerciseEditView: View {
    var exercise: Exercise?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var name = ""
    @State private var group: MuscleGroup = .other
    @State private var bodyweight = false
    @State private var notes = ""

    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Lift") {
                    TextField("Name", text: $name)
                    Picker("Group", selection: $group) {
                        ForEach(MuscleGroup.allCases) { Text($0.label).tag($0) }
                    }
                    Toggle("Bodyweight movement", isOn: $bodyweight)
                }
                Section("Notes") {
                    TextField("Cues, setup…", text: $notes, axis: .vertical).lineLimit(2...6)
                }
            }
            .scrollContentBackground(.hidden).background(Brand.pageBackground)
            .navigationTitle(exercise == nil ? "New Lift" : "Edit Lift")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(!canSave).fontWeight(.semibold)
                }
            }
            .onAppear {
                if let e = exercise { name = e.name; group = e.group; bodyweight = e.isBodyweight; notes = e.notes }
            }
        }
    }

    private func save() {
        let target = exercise ?? Exercise(name: "")
        target.name = name.trimmingCharacters(in: .whitespaces)
        target.group = group
        target.isBodyweight = bodyweight
        target.notes = notes
        if exercise == nil { context.insert(target) }
        try? context.save(); Haptics.success(); dismiss()
    }
}
