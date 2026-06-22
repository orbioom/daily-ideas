import SwiftUI
import SwiftData

struct FoodLogView: View {
    @Query(sort: \FoodLogEntry.date, order: .reverse) private var entries: [FoodLogEntry]
    @State private var showingEditor = false
    @State private var editingEntry: FoodLogEntry?
    @State private var selectedDate = Date()

    private var todayEntries: [FoodLogEntry] {
        let cal = Calendar.current
        return entries.filter { cal.isDate($0.date, inSameDayAs: selectedDate) }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                DatePicker("", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding(.horizontal)
                    .padding(.top, 8)

                Divider()

                if todayEntries.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(MealType.allCases) { mealType in
                            let mealEntries = todayEntries.filter { $0.mealType == mealType.rawValue }
                            if !mealEntries.isEmpty {
                                Section {
                                    ForEach(mealEntries) { entry in
                                        FoodEntryRow(entry: entry) { editingEntry = entry }
                                    }
                                    .onDelete { delete(mealEntries, offsets: $0) }
                                } header: {
                                    Label(mealType.displayName, systemImage: mealType.icon)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Food Log")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingEditor = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingEditor) {
                FoodLogEditorView(entry: nil, prefillDate: selectedDate)
            }
            .sheet(item: $editingEntry) { entry in
                FoodLogEditorView(entry: entry, prefillDate: entry.date)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 56))
                .foregroundStyle(NourishTheme.sage.opacity(0.5))
            Text("No meals logged")
                .font(.title3.weight(.semibold))
            Text("Tap + to log a meal for this day.")
                .foregroundStyle(NourishTheme.secondaryText)
            Spacer()
        }
    }

    private func delete(_ list: [FoodLogEntry], offsets: IndexSet) {}
}

private struct FoodEntryRow: View {
    let entry: FoodLogEntry
    let onEdit: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.foodName)
                    .font(.subheadline.weight(.medium))
                if !entry.allergenTags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(entry.allergenTags.prefix(3), id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(NourishTheme.terra.opacity(0.15), in: Capsule())
                                .foregroundStyle(NourishTheme.terra)
                        }
                    }
                }
            }
            Spacer()
            Text(entry.portionNote)
                .font(.caption)
                .foregroundStyle(NourishTheme.secondaryText)
        }
        .contentShape(Rectangle())
        .onTapGesture { onEdit() }
    }
}
