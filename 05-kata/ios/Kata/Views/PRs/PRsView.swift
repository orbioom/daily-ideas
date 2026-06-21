import SwiftUI
import SwiftData

struct PRsView: View {
    @Query(sort: \PersonalRecord.movement) private var records: [PersonalRecord]
    @Environment(\.modelContext) private var modelContext
    @State private var showAdd = false
    @State private var searchText = ""
    @State private var selectedCategory: MovementCategory? = nil

    var filtered: [PersonalRecord] {
        records.filter { r in
            let matchSearch = searchText.isEmpty || r.movement.localizedCaseInsensitiveContains(searchText)
            let matchCat = selectedCategory == nil || r.category == selectedCategory!.rawValue
            return matchSearch && matchCat
        }
    }

    var body: some View {
        ZStack {
            KataTheme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                categoryFilter
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                if filtered.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(filtered) { pr in
                            PRRow(record: pr)
                                .swipeActions {
                                    Button(role: .destructive) {
                                        modelContext.delete(pr)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .listStyle(.insetGrouped)
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search movements")
        .navigationTitle("Personal Records")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(KataTheme.background, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showAdd = true } label: {
                    Image(systemName: "plus").foregroundStyle(KataTheme.accent)
                }
            }
        }
        .sheet(isPresented: $showAdd) { AddPRView() }
    }

    var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                catChip(label: "All", cat: nil)
                ForEach(MovementCategory.allCases, id: \.self) { c in
                    catChip(label: c.rawValue, cat: c)
                }
            }
        }
    }

    func catChip(label: String, cat: MovementCategory?) -> some View {
        Button {
            withAnimation { selectedCategory = cat }
        } label: {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(selectedCategory == cat ? .black : KataTheme.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selectedCategory == cat ? KataTheme.accentYellow : KataTheme.surface, in: Capsule())
        }
    }

    var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 52))
                .foregroundStyle(KataTheme.textSecondary)
            Text("No PRs Yet")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(KataTheme.textPrimary)
            Text("Log your personal records to track your strength progress.")
                .font(.system(size: 15))
                .foregroundStyle(KataTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button { showAdd = true } label: {
                Text("Add PR")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(KataTheme.accentYellow, in: Capsule())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct PRRow: View {
    let record: PersonalRecord

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.movement)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(KataTheme.textPrimary)
                HStack(spacing: 8) {
                    Text(record.category)
                        .font(.system(size: 12))
                        .foregroundStyle(KataTheme.textSecondary)
                    Text("·")
                        .foregroundStyle(KataTheme.textSecondary)
                    Text(record.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 12))
                        .foregroundStyle(KataTheme.textSecondary)
                }
                if !record.notes.isEmpty {
                    Text(record.notes)
                        .font(.system(size: 12))
                        .foregroundStyle(KataTheme.textSecondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            Text(record.display)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(KataTheme.accentYellow)
        }
        .padding(.vertical, 4)
        .listRowBackground(KataTheme.surface)
    }
}

struct AddPRView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var movement = ""
    @State private var weight = ""
    @State private var unit = "lb"
    @State private var category = MovementCategory.weightlifting
    @State private var notes = ""
    @State private var showMovementPicker = false

    let units = ["lb", "kg"]

    var body: some View {
        NavigationStack {
            ZStack {
                KataTheme.background.ignoresSafeArea()
                Form {
                    Section {
                        HStack {
                            TextField("Movement", text: $movement)
                            Button {
                                showMovementPicker = true
                            } label: {
                                Image(systemName: "list.bullet")
                                    .foregroundStyle(KataTheme.accent)
                            }
                        }
                        Picker("Category", selection: $category) {
                            ForEach(MovementCategory.allCases, id: \.self) { c in
                                Text(c.rawValue).tag(c)
                            }
                        }
                    } header: {
                        Text("Movement").foregroundStyle(KataTheme.textSecondary)
                    }
                    .listRowBackground(KataTheme.surface)
                    .foregroundStyle(KataTheme.textPrimary)

                    Section {
                        HStack {
                            TextField("Weight", text: $weight)
                                .keyboardType(.decimalPad)
                            Picker("Unit", selection: $unit) {
                                ForEach(units, id: \.self) { Text($0).tag($0) }
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 100)
                        }
                    } header: {
                        Text("PR Weight").foregroundStyle(KataTheme.textSecondary)
                    }
                    .listRowBackground(KataTheme.surface)
                    .foregroundStyle(KataTheme.textPrimary)

                    Section {
                        TextField("Notes (form cues, conditions, etc.)", text: $notes, axis: .vertical)
                            .lineLimit(3...6)
                    } header: {
                        Text("Notes").foregroundStyle(KataTheme.textSecondary)
                    }
                    .listRowBackground(KataTheme.surface)
                    .foregroundStyle(KataTheme.textPrimary)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("New PR")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(KataTheme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundStyle(KataTheme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .foregroundStyle(KataTheme.accentYellow)
                        .disabled(movement.isEmpty || weight.isEmpty)
                }
            }
            .sheet(isPresented: $showMovementPicker) {
                MovementPickerView(selected: $movement)
            }
        }
    }

    func save() {
        let pr = PersonalRecord(
            movement: movement,
            weight: Double(weight) ?? 0,
            unit: unit,
            notes: notes,
            category: category.rawValue
        )
        modelContext.insert(pr)
        dismiss()
    }
}

struct MovementPickerView: View {
    @Binding var selected: String
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""

    var filtered: [String] {
        search.isEmpty ? commonMovements : commonMovements.filter { $0.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                KataTheme.background.ignoresSafeArea()
                List(filtered, id: \.self) { m in
                    Button {
                        selected = m
                        dismiss()
                    } label: {
                        Text(m).foregroundStyle(KataTheme.textPrimary)
                    }
                    .listRowBackground(KataTheme.surface)
                }
                .scrollContentBackground(.hidden)
            }
            .searchable(text: $search, prompt: "Search movements")
            .navigationTitle("Choose Movement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(KataTheme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundStyle(KataTheme.textSecondary)
                }
            }
        }
    }
}
