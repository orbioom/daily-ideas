import SwiftUI
import SwiftData

struct AddTrailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var trailToEdit: Trail? = nil

    @State private var name: String = ""
    @State private var location: String = ""
    @State private var trailDescription: String = ""
    @State private var distanceKm: String = ""
    @State private var elevationGainM: String = ""
    @State private var difficulty: TrailDifficulty = .moderate
    @State private var isFavorite: Bool = false
    @State private var showValidationAlert = false

    var isEditing: Bool { trailToEdit != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Trail Info") {
                    TextField("Trail name", text: $name)
                        .accessibilityLabel("Trail name")
                    TextField("Location (e.g. Yosemite, CA)", text: $location)
                        .accessibilityLabel("Location")
                }

                Section("Details") {
                    HStack {
                        TextField("Distance", text: $distanceKm)
                            .keyboardType(.decimalPad)
                            .accessibilityLabel("Distance in kilometers")
                        Text("km")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        TextField("Elevation gain", text: $elevationGainM)
                            .keyboardType(.decimalPad)
                            .accessibilityLabel("Elevation gain in meters")
                        Text("m")
                            .foregroundStyle(.secondary)
                    }
                    Picker("Difficulty", selection: $difficulty) {
                        ForEach(TrailDifficulty.allCases, id: \.self) { d in
                            Label(d.rawValue, systemImage: d.icon)
                                .tag(d)
                        }
                    }
                }

                Section("Notes") {
                    TextEditor(text: $trailDescription)
                        .frame(minHeight: 80)
                        .accessibilityLabel("Trail description")
                }

                Section {
                    Toggle("Mark as Favorite", isOn: $isFavorite)
                        .tint(TrekTheme.sunGold)
                }
            }
            .navigationTitle(isEditing ? "Edit Trail" : "New Trail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .alert("Missing Info", isPresented: $showValidationAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please enter a trail name.")
            }
            .onAppear {
                if let t = trailToEdit {
                    name = t.name
                    location = t.location
                    trailDescription = t.trailDescription
                    distanceKm = t.distanceKm > 0 ? String(format: "%.1f", t.distanceKm) : ""
                    elevationGainM = t.elevationGainM > 0 ? String(format: "%.0f", t.elevationGainM) : ""
                    difficulty = t.difficulty
                    isFavorite = t.isFavorite
                }
            }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            showValidationAlert = true
            return
        }

        let dist = Double(distanceKm.replacingOccurrences(of: ",", with: ".")) ?? 0
        let elev = Double(elevationGainM.replacingOccurrences(of: ",", with: ".")) ?? 0

        if let t = trailToEdit {
            t.name = trimmedName
            t.location = location
            t.trailDescription = trailDescription
            t.distanceKm = dist
            t.elevationGainM = elev
            t.difficulty = difficulty
            t.isFavorite = isFavorite
        } else {
            let trail = Trail(
                name: trimmedName,
                location: location,
                trailDescription: trailDescription,
                distanceKm: dist,
                elevationGainM: elev,
                difficulty: difficulty,
                isFavorite: isFavorite
            )
            context.insert(trail)
        }
        dismiss()
    }
}
