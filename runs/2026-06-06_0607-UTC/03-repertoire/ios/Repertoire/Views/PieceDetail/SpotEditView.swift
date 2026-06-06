import SwiftUI
import SwiftData

/// Create or edit a practice spot. Validates a non-empty name; clamps tempos and mastery.
struct SpotEditView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var piece: Piece
    /// nil → new spot; non-nil → editing.
    var spot: PracticeSpot?

    @State private var name = ""
    @State private var currentTempo = 80
    @State private var targetTempo = 120
    @State private var hasTarget = true
    @State private var mastery = 0
    @State private var notes = ""
    @State private var showingDeleteConfirm = false

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var isValid: Bool { !trimmedName.isEmpty }
    private var isEditing: Bool { spot != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Spot") {
                    TextField("Name (e.g. bars 32–40 LH)", text: $name)
                        .textInputAutocapitalization(.sentences)
                }

                Section("Tempo") {
                    Stepper(value: $currentTempo, in: Tempo.min...Tempo.max) {
                        HStack {
                            Text("Current")
                            Spacer()
                            Text("\(currentTempo) BPM")
                                .font(Brand.mono(15)).monospacedDigit()
                                .foregroundStyle(Brand.text2)
                        }
                    }
                    Toggle("Has a target", isOn: $hasTarget.animation(Brand.ease(0.25)))
                    if hasTarget {
                        Stepper(value: $targetTempo, in: Tempo.min...Tempo.max) {
                            HStack {
                                Text("Target")
                                Spacer()
                                Text("\(targetTempo) BPM")
                                    .font(Brand.mono(15)).monospacedDigit()
                                    .foregroundStyle(Brand.text2)
                            }
                        }
                    }
                }

                Section("Mastery") {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Level")
                            Spacer()
                            MasteryDots(level: mastery, size: 11)
                        }
                        Slider(value: Binding(
                            get: { Double(mastery) },
                            set: { mastery = Int($0.rounded()) }
                        ), in: 0...5, step: 1)
                        .tint(Brand.live)
                        .accessibilityValue("\(mastery) of 5")
                    }
                }

                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(2...5)
                }

                if isEditing {
                    Section {
                        Button(role: .destructive) {
                            showingDeleteConfirm = true
                        } label: {
                            Label("Delete spot", systemImage: "trash")
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle(isEditing ? "Edit Spot" : "New Spot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!isValid)
                        .fontWeight(.semibold)
                }
            }
            .alert("Delete this spot?", isPresented: $showingDeleteConfirm) {
                Button("Delete", role: .destructive) { delete() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes the spot and its tempo progress. This can't be undone.")
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard let spot else {
            currentTempo = settings.defaultBPM
            return
        }
        name = spot.name
        currentTempo = spot.currentTempo > 0 ? spot.currentTempo : settings.defaultBPM
        hasTarget = spot.targetTempo >= Tempo.min
        targetTempo = spot.targetTempo >= Tempo.min ? spot.targetTempo : max(currentTempo, Tempo.min)
        mastery = spot.clampedMastery
        notes = spot.notes
    }

    private func save() {
        guard isValid else { return }
        let resolvedTarget = hasTarget ? Tempo.clamp(targetTempo) : 0
        if let spot {
            spot.name = trimmedName
            spot.currentTempo = Tempo.clamp(currentTempo)
            spot.targetTempo = resolvedTarget
            spot.mastery = min(5, max(0, mastery))
            spot.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            let order = (piece.spots.map { $0.order }.max() ?? -1) + 1
            let newSpot = PracticeSpot(
                name: trimmedName,
                order: order,
                currentTempo: Tempo.clamp(currentTempo),
                targetTempo: resolvedTarget,
                mastery: min(5, max(0, mastery)),
                notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            newSpot.piece = piece
            piece.spots.append(newSpot)
            context.insert(newSpot)
        }
        Haptics.success(enabled: settings.hapticsEnabled)
        dismiss()
    }

    private func delete() {
        guard let spot else { return }
        context.delete(spot)
        Haptics.warning(enabled: settings.hapticsEnabled)
        dismiss()
    }
}

#Preview {
    SpotEditView(piece: PreviewData.samplePiece, spot: nil)
        .environment(SettingsStore())
        .previewContainer()
}
