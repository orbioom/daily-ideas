import SwiftUI
import SwiftData

struct EntryEditView: View {
    var entry: MoodEntry?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \Activity.order) private var activities: [Activity]

    @State private var mood = 3
    @State private var note = ""
    @State private var date = Date()
    @State private var selected: Set<UUID> = []

    private var grouped: [(String, [Activity])] {
        let active = activities.filter { !$0.isArchived }
        let cats = Array(Set(active.map(\.category)))
        return cats.sorted().map { cat in (cat, active.filter { $0.category == cat }.sorted { $0.order < $1.order }) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        VStack(spacing: 10) {
                            Text(Mood.label(mood))
                                .font(.title.weight(.bold))
                                .foregroundStyle(Brand.text)
                                .contentTransition(.opacity)
                            MoodPicker(value: $mood)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)

                        VStack(alignment: .leading, spacing: 10) {
                            Eyebrow(text: "WHAT WERE YOU UP TO?")
                            if grouped.isEmpty {
                                Text("No activities yet — add some on the Activities tab.")
                                    .font(.subheadline).foregroundStyle(Brand.text2)
                            }
                            ForEach(grouped, id: \.0) { cat, items in
                                Text(cat).font(.caption).foregroundStyle(Brand.text3)
                                WrapChips(items: items) { activity in
                                    Button {
                                        toggle(activity.id)
                                    } label: {
                                        ActivityChip(symbol: activity.symbol, name: activity.name,
                                                     selected: selected.contains(activity.id))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Eyebrow(text: "NOTE")
                            TextField("Anything on your mind?", text: $note, axis: .vertical)
                                .lineLimit(2...6)
                                .foregroundStyle(Brand.text)
                                .padding(12)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                        }

                        DatePicker("When", selection: $date, in: ...Date())
                            .foregroundStyle(Brand.text)
                    }
                    .padding(20)
                }
            }
            .navigationTitle(entry == nil ? "New check-in" : "Edit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() } }
            }
            .onAppear(perform: load)
        }
    }

    private func toggle(_ id: UUID) {
        if selected.contains(id) { selected.remove(id) } else { selected.insert(id) }
        Haptics.selection()
    }

    private func load() {
        guard let entry else { return }
        mood = entry.mood; note = entry.note; date = entry.date
        selected = Set(entry.activities.map(\.id))
    }

    private func save() {
        let chosen = activities.filter { selected.contains($0.id) }
        if let entry {
            entry.mood = mood; entry.note = note; entry.date = date; entry.activities = chosen
        } else {
            context.insert(MoodEntry(date: date, mood: mood, note: note, activities: chosen))
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
