import SwiftUI
import SwiftData

/// Create or edit a climb: name (optional), discipline, grade, location, hold color,
/// set date, project flag, notes. Cancelling a new climb removes the stub.
struct ClimbEditView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Location.name) private var locations: [Location]

    @Bindable var climb: Climb
    var isNew: Bool

    @State private var name: String
    @State private var discipline: Discipline
    @State private var gradeIndex: Int
    @State private var locationID: UUID?
    @State private var hasColor: Bool
    @State private var colorIndex: Int
    @State private var hasSetDate: Bool
    @State private var setDate: Date
    @State private var isProject: Bool
    @State private var notes: String
    @State private var showingNewLocation = false

    init(climb: Climb, isNew: Bool) {
        self.climb = climb
        self.isNew = isNew
        _name = State(initialValue: climb.name)
        _discipline = State(initialValue: climb.discipline)
        _gradeIndex = State(initialValue: climb.gradeIndex)
        _locationID = State(initialValue: climb.location?.id)
        _hasColor = State(initialValue: climb.hasColor)
        _colorIndex = State(initialValue: max(climb.colorIndex, 0))
        _hasSetDate = State(initialValue: climb.setDate != nil)
        _setDate = State(initialValue: climb.setDate ?? .now)
        _isProject = State(initialValue: climb.isProject)
        _notes = State(initialValue: climb.notes)
    }

    private var system: GradeSystem { settings.system(for: discipline.family) }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Optional — e.g. Blue Slab", text: $name)
                        .textInputAutocapitalization(.words)
                }

                Section("Discipline") {
                    Picker("Discipline", selection: $discipline) {
                        ForEach(Discipline.allCases) { d in
                            Label(d.title, systemImage: d.symbol).tag(d)
                        }
                    }
                    .onChange(of: discipline) { _, newValue in
                        // Switching families re-clamps the grade so it stays valid.
                        gradeIndex = GradeScale.clampedIndex(gradeIndex, family: newValue.family) ?? 0
                    }
                }

                Section("Grade (\(system.title))") {
                    GradePicker(family: discipline.family, system: system, index: $gradeIndex)
                        .frame(height: 120)
                }

                Section("Location") {
                    Picker("Location", selection: $locationID) {
                        Text("None").tag(UUID?.none)
                        ForEach(locations) { location in
                            Text(location.name).tag(UUID?.some(location.id))
                        }
                    }
                    Button { showingNewLocation = true } label: {
                        Label("Add location", systemImage: "plus.circle")
                    }
                }

                Section("Gym problem details") {
                    Toggle("Hold color", isOn: $hasColor)
                    if hasColor {
                        colorRow
                    }
                    Toggle("Set date", isOn: $hasSetDate)
                    if hasSetDate {
                        DatePicker("Set", selection: $setDate, displayedComponents: .date)
                    }
                }

                Section {
                    Toggle("Project", isOn: $isProject)
                } footer: {
                    Text("Projects are climbs you're actively working toward. Once sent, they show as complete.")
                }

                Section("Notes") {
                    TextField("Beta, conditions, reminders…", text: $notes, axis: .vertical)
                        .lineLimit(2...5)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle(isNew ? "New Climb" : "Edit Climb")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { cancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingNewLocation) {
                LocationEditView { newLocation in
                    locationID = newLocation.id
                }
            }
        }
    }

    private var colorRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Brand.holdPalette.indices, id: \.self) { i in
                    Button {
                        colorIndex = i
                    } label: {
                        Circle()
                            .fill(Brand.holdColor(i))
                            .frame(width: 28, height: 28)
                            .overlay(
                                Circle().strokeBorder(Brand.text,
                                                      lineWidth: colorIndex == i ? 2.5 : 0)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Hold color \(i + 1)")
                    .accessibilityAddTraits(colorIndex == i ? .isSelected : [])
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func save() {
        climb.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        climb.discipline = discipline
        climb.gradeIndex = GradeScale.clampedIndex(gradeIndex, family: discipline.family) ?? 0
        climb.location = locations.first { $0.id == locationID }
        climb.colorIndex = hasColor ? colorIndex : -1
        climb.setDate = hasSetDate ? setDate : nil
        climb.isProject = isProject
        climb.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        Haptics.success(enabled: settings.hapticsEnabled)
        dismiss()
    }

    private func cancel() {
        if isNew && climb.attempts.isEmpty {
            context.delete(climb)
        }
        dismiss()
    }
}
