import SwiftUI
import SwiftData

struct SpotsView: View {
    @Query(sort: \SurfSpot.name) private var spots: [SurfSpot]
    @Environment(\.modelContext) private var context
    @State private var showingAdd = false
    @State private var editSpot: SurfSpot?

    var body: some View {
        Group {
            if spots.isEmpty {
                emptyState
                    .toolbar { addButton }
            } else {
                List {
                    ForEach(spots) { spot in
                        SpotRowView(spot: spot)
                            .onTapGesture { editSpot = spot }
                            .swipeActions(edge: .leading) {
                                Button {
                                    spot.isFavorite.toggle()
                                    try? context.save()
                                } label: {
                                    Label(spot.isFavorite ? "Unfavorite" : "Favorite",
                                          systemImage: spot.isFavorite ? "star.slash" : "star.fill")
                                }
                                .tint(.yellow)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    context.delete(spot)
                                    try? context.save()
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
                .listStyle(.insetGrouped)
                .toolbar { addButton }
            }
        }
        .sheet(isPresented: $showingAdd) { SpotFormView(spot: nil) }
        .sheet(item: $editSpot) { spot in SpotFormView(spot: spot) }
    }

    private var addButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button { showingAdd = true } label: {
                Image(systemName: "plus")
                    .foregroundStyle(SwellTheme.teal)
            }
            .accessibilityLabel("Add spot")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "mappin.and.ellipse")
                .font(.system(size: 56))
                .foregroundStyle(SwellTheme.teal.opacity(0.5))
                .accessibilityHidden(true)
            Text("No spots saved")
                .font(.title3.bold())
            Text("Save your favorite breaks to pick them quickly when logging.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct SpotRowView: View {
    let spot: SurfSpot

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 8)
                .fill(spot.difficulty.swiftUIColor.opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: spot.breakType.sfSymbol)
                        .foregroundStyle(spot.difficulty.swiftUIColor)
                }
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(spot.name)
                        .font(.subheadline.bold())
                    if spot.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    }
                }
                Text("\(spot.breakType.rawValue) • \(spot.difficulty.rawValue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(spot.name), \(spot.breakType.rawValue), \(spot.difficulty.rawValue)\(spot.isFavorite ? ", favorite" : "")")
    }
}

struct SpotFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let spot: SurfSpot?

    @State private var name: String
    @State private var breakType: BreakType
    @State private var difficulty: SpotDifficulty
    @State private var notes: String
    @State private var isFavorite: Bool
    @State private var showError = false

    init(spot: SurfSpot?) {
        self.spot = spot
        _name = State(initialValue: spot?.name ?? "")
        _breakType = State(initialValue: spot?.breakType ?? .beach)
        _difficulty = State(initialValue: spot?.difficulty ?? .intermediate)
        _notes = State(initialValue: spot?.notes ?? "")
        _isFavorite = State(initialValue: spot?.isFavorite ?? false)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Spot") {
                    TextField("Name", text: $name)
                    Picker("Break Type", selection: $breakType) {
                        ForEach(BreakType.allCases) { b in
                            Label(b.rawValue, systemImage: b.sfSymbol).tag(b)
                        }
                    }
                    Picker("Difficulty", selection: $difficulty) {
                        ForEach(SpotDifficulty.allCases) { d in Text(d.rawValue).tag(d) }
                    }
                }
                Section {
                    Toggle("Favorite", isOn: $isFavorite)
                    TextField("Notes", text: $notes)
                }
            }
            .navigationTitle(spot == nil ? "Add Spot" : "Edit Spot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                        .fontWeight(.semibold)
                        .foregroundStyle(SwellTheme.teal)
                }
            }
            .alert("Please enter a spot name.", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { showError = true; return }
        if let s = spot {
            s.name = trimmed; s.breakType = breakType; s.difficulty = difficulty
            s.notes = notes; s.isFavorite = isFavorite
        } else {
            let s = SurfSpot(name: trimmed, breakType: breakType, difficulty: difficulty, notes: notes, isFavorite: isFavorite)
            context.insert(s)
        }
        try? context.save()
        dismiss()
    }
}
