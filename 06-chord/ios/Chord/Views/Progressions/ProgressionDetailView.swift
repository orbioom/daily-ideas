import SwiftUI
import SwiftData

struct ProgressionDetailView: View {
    @Environment(\.modelContext) private var context
    @Bindable var progression: Progression
    @State private var showAddChord = false
    @State private var showEdit = false
    @State private var engine = ChordEngine()
    @AppStorage(ChordSettings.showRomanNumerals) private var showRomanNumerals = true
    @AppStorage(ChordSettings.hapticFeedback) private var hapticFeedback = true

    var body: some View {
        List {
            Section {
                progressionHeader
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())

            Section {
                if progression.sortedChords.isEmpty {
                    Button {
                        showAddChord = true
                    } label: {
                        Label("Add First Chord", systemImage: "plus.circle.fill")
                            .foregroundStyle(ChordTheme.teal)
                    }
                } else {
                    ForEach(progression.sortedChords) { slot in
                        ChordSlotRow(slot: slot, keyName: progression.keyName,
                                     showRomanNumerals: showRomanNumerals, engine: engine)
                    }
                    .onMove { from, to in
                        var sorted = progression.sortedChords
                        sorted.move(fromOffsets: from, toOffset: to)
                        for (i, s) in sorted.enumerated() { s.position = i }
                        progression.modifiedDate = Date()
                    }
                    .onDelete { offsets in
                        let sorted = progression.sortedChords
                        for i in offsets { context.delete(sorted[i]) }
                        progression.modifiedDate = Date()
                    }
                }
            } header: {
                HStack {
                    Text("Chords")
                    Spacer()
                    Button {
                        showAddChord = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(ChordTheme.teal)
                    }
                    .accessibilityLabel("Add chord")
                }
            }

            if !progression.notes.isEmpty {
                Section("Notes") {
                    Text(progression.notes)
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }
            }
        }
        .navigationTitle(progression.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { showEdit = true }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    progression.isFavorite.toggle()
                    if hapticFeedback {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                } label: {
                    Image(systemName: progression.isFavorite ? "star.fill" : "star")
                        .foregroundStyle(progression.isFavorite ? .yellow : .secondary)
                }
                .accessibilityLabel(progression.isFavorite ? "Remove from favorites" : "Add to favorites")
            }
        }
        .sheet(isPresented: $showAddChord) {
            AddChordView(progression: progression)
        }
        .sheet(isPresented: $showEdit) {
            EditProgressionView(progression: progression)
        }
    }

    private var progressionHeader: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                infoCard("Key", value: progression.keyName, icon: "music.note")
                infoCard("BPM", value: "\(progression.tempo)", icon: "metronome.fill")
                infoCard("Genre", value: progression.genre.rawValue, icon: progression.genre.icon)
            }

            if !progression.sortedChords.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(progression.sortedChords) { slot in
                            VStack(spacing: 2) {
                                Text(slot.chordName)
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                Text(slot.duration.rawValue + "b")
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(ChordTheme.qualityColor(slot.quality), in: RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .padding()
    }

    private func infoCard(_ label: String, value: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.caption).foregroundStyle(ChordTheme.teal).accessibilityHidden(true)
            Text(value).font(.system(size: 18, weight: .bold, design: .rounded))
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

struct ChordSlotRow: View {
    @Bindable var slot: ChordSlot
    let keyName: String
    let showRomanNumerals: Bool
    let engine: ChordEngine

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(ChordTheme.qualityColor(slot.quality).opacity(0.15))
                    .frame(width: 48, height: 48)
                Text(slot.chordName)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(ChordTheme.qualityColor(slot.quality))
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(slot.fullName)
                    .font(.subheadline.weight(.medium))
                HStack(spacing: 8) {
                    Text(slot.duration.displayName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    if showRomanNumerals {
                        let roman = engine.romanNumeral(for: slot, inKey: keyName)
                        if !roman.isEmpty {
                            Text(roman)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(ChordTheme.teal)
                        }
                    }
                }
            }

            Spacer()

            if !slot.lyricHint.isEmpty {
                Text(slot.lyricHint)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(slot.fullName), \(slot.duration.displayName)")
    }
}

struct EditProgressionView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var progression: Progression
    @State private var title: String = ""
    @State private var keyName: String = "C"
    @State private var genre: ProgressionGenre = .pop
    @State private var tempo: Int = 120
    @State private var notes: String = ""

    private let rootNotes = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B",
                              "Db", "Eb", "Ab", "Bb"]

    var body: some View {
        NavigationStack {
            Form {
                Section { TextField("Title", text: $title) }
                Section {
                    Picker("Key", selection: $keyName) {
                        ForEach(rootNotes, id: \.self) { n in Text(n).tag(n) }
                    }
                    Picker("Genre", selection: $genre) {
                        ForEach(ProgressionGenre.allCases, id: \.self) { g in
                            Label(g.rawValue, systemImage: g.icon).tag(g)
                        }
                    }
                    Stepper("Tempo: \(tempo) BPM", value: $tempo, in: 40...240, step: 5)
                }
                Section { TextField("Notes", text: $notes, axis: .vertical).lineLimit(3...6) }
            }
            .navigationTitle("Edit Progression")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let t = title.trimmingCharacters(in: .whitespaces)
                        guard !t.isEmpty else { return }
                        progression.title = t; progression.keyName = keyName
                        progression.genre = genre; progression.tempo = tempo
                        progression.notes = notes; progression.modifiedDate = Date()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                title = progression.title; keyName = progression.keyName
                genre = progression.genre; tempo = progression.tempo; notes = progression.notes
            }
        }
    }
}
