import SwiftUI
import SwiftData

/// Create or edit a piece. Validates and trims input; a piece needs a non-empty title.
/// Spots are managed inline here on create and from the detail screen later.
struct PieceEditView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    /// nil → creating a new piece; non-nil → editing an existing one.
    var piece: Piece?

    @State private var title = ""
    @State private var composer = ""
    @State private var instrument = "Piano"
    @State private var difficulty: Difficulty = .intermediate
    @State private var status: PieceStatus = .learning
    @State private var key = ""
    @State private var targetTempo = 0
    @State private var hasTarget = false
    @State private var notes = ""

    @State private var draftSpots: [DraftSpot] = []

    private let instruments = ["Piano", "Guitar", "Jazz Guitar", "Violin", "Cello",
                               "Flute", "Clarinet", "Voice", "Drums", "Bass", "Other"]

    private var trimmedTitle: String { title.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var isValid: Bool { !trimmedTitle.isEmpty }
    private var isEditing: Bool { piece != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Piece") {
                    TextField("Title", text: $title)
                        .textInputAutocapitalization(.words)
                    TextField("Composer", text: $composer)
                        .textInputAutocapitalization(.words)
                    Picker("Instrument", selection: $instrument) {
                        ForEach(instruments, id: \.self) { Text($0).tag($0) }
                    }
                    TextField("Key (e.g. D♭ major)", text: $key)
                }

                Section("Detail") {
                    Picker("Status", selection: $status) {
                        ForEach(PieceStatus.allCases) { s in
                            Label(s.title, systemImage: s.systemImage).tag(s)
                        }
                    }
                    Picker("Difficulty", selection: $difficulty) {
                        ForEach(Difficulty.allCases) { d in
                            Text(d.title).tag(d)
                        }
                    }
                    Toggle("Set a target tempo", isOn: $hasTarget.animation(Brand.ease(0.25)))
                    if hasTarget {
                        Stepper(value: $targetTempo, in: Tempo.min...Tempo.max, step: 1) {
                            HStack {
                                Text("Target tempo")
                                Spacer()
                                Text("\(targetTempo) BPM")
                                    .font(Brand.mono(15))
                                    .foregroundStyle(Brand.text2)
                                    .monospacedDigit()
                            }
                        }
                    }
                }

                if !isEditing {
                    Section {
                        ForEach($draftSpots) { $spot in
                            DraftSpotRow(spot: $spot)
                        }
                        .onDelete { draftSpots.remove(atOffsets: $0) }
                        Button {
                            draftSpots.append(DraftSpot())
                        } label: {
                            Label("Add a spot", systemImage: "plus")
                        }
                    } header: {
                        Text("Practice spots")
                    } footer: {
                        Text("Name the passages or skills you'll drill. You can add more later.")
                    }
                }

                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(2...6)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle(isEditing ? "Edit Piece" : "New Piece")
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
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard let piece else {
            if draftSpots.isEmpty { draftSpots = [DraftSpot()] }
            if !hasTarget { targetTempo = settings.defaultBPM }
            return
        }
        title = piece.title
        composer = piece.composer
        instrument = piece.instrument
        difficulty = piece.difficulty
        status = piece.status
        key = piece.key
        hasTarget = piece.hasTarget
        targetTempo = piece.hasTarget ? piece.targetTempo : settings.defaultBPM
        notes = piece.notes
    }

    private func save() {
        guard isValid else { return }
        let resolvedTarget = hasTarget ? Tempo.clamp(targetTempo) : 0

        if let piece {
            piece.title = trimmedTitle
            piece.composer = composer.trimmingCharacters(in: .whitespacesAndNewlines)
            piece.instrument = instrument
            piece.difficulty = difficulty
            piece.status = status
            piece.key = key.trimmingCharacters(in: .whitespacesAndNewlines)
            piece.targetTempo = resolvedTarget
            piece.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            let newPiece = Piece(
                title: trimmedTitle,
                composer: composer.trimmingCharacters(in: .whitespacesAndNewlines),
                instrument: instrument,
                difficulty: difficulty,
                status: status,
                targetTempo: resolvedTarget,
                key: key.trimmingCharacters(in: .whitespacesAndNewlines),
                notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            context.insert(newPiece)
            var order = 0
            for draft in draftSpots {
                let name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !name.isEmpty else { continue }
                let spot = PracticeSpot(
                    name: name,
                    order: order,
                    currentTempo: Tempo.clamp(draft.current),
                    targetTempo: draft.hasTarget ? Tempo.clamp(draft.target) : 0,
                    mastery: min(5, max(0, draft.mastery))
                )
                spot.piece = newPiece
                newPiece.spots.append(spot)
                context.insert(spot)
                order += 1
            }
        }
        Haptics.success(enabled: settings.hapticsEnabled)
        dismiss()
    }
}

/// A transient spot being composed in the new-piece form.
struct DraftSpot: Identifiable {
    let id = UUID()
    var name = ""
    var current = 80
    var target = 120
    var hasTarget = true
    var mastery = 0
}

private struct DraftSpotRow: View {
    @Binding var spot: DraftSpot

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Spot name (e.g. bars 32–40)", text: $spot.name)
            Toggle("Target tempo", isOn: $spot.hasTarget.animation(Brand.ease(0.2)))
                .font(.subheadline)
            if spot.hasTarget {
                Stepper(value: $spot.target, in: Tempo.min...Tempo.max) {
                    HStack {
                        Text("Target").font(.subheadline).foregroundStyle(Brand.text2)
                        Spacer()
                        Text("\(spot.target) BPM").font(Brand.mono(14)).monospacedDigit()
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    PieceEditView(piece: nil)
        .environment(SettingsStore())
        .previewContainer()
}
