import SwiftUI
import SwiftData

struct SongEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let existing: Song?

    @AppStorage("capo.defaultKey") private var defaultKey = "C"
    @State private var title = ""
    @State private var artist = ""
    @State private var key = "C"
    @State private var bpm = 0
    @State private var capo = 0
    @State private var timeSignature = "4/4"
    @State private var notes = ""
    @State private var sections: [SectionDraft] = []

    struct SectionDraft: Identifiable { let id = UUID(); var name: String; var content: String }

    private let keys = ["C","C#","Db","D","D#","Eb","E","F","F#","Gb","G","G#","Ab","A","A#","Bb","B",
                        "Am","Bm","Cm","C#m","Dm","D#m","Ebm","Em","Fm","F#m","Gm","G#m"]
    private let times = ["4/4","3/4","6/8","2/4","12/8"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    basicsCard
                    metaCard
                    sectionsCard
                    notesCard
                }
                .padding()
            }
            .navigationTitle(existing == nil ? "New Song" : "Edit Song")
            .navigationBarTitleDisplayMode(.inline)
            .background(Brand.pageBackground)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear(perform: load)
        }
    }

    private var basicsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Title", text: $title).font(.headline).foregroundStyle(Brand.text)
            Divider().overlay(Brand.hairline)
            TextField("Artist", text: $artist).font(.subheadline).foregroundStyle(Brand.text2)
        }.glassCard()
    }

    private var metaCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Key").foregroundStyle(Brand.text2)
                Spacer()
                Picker("Key", selection: $key) { ForEach(keys, id: \.self) { Text($0).tag($0) } }
                    .tint(Brand.text)
            }
            Divider().overlay(Brand.hairline)
            HStack {
                Text("Time").foregroundStyle(Brand.text2)
                Spacer()
                Picker("Time", selection: $timeSignature) { ForEach(times, id: \.self) { Text($0).tag($0) } }
                    .tint(Brand.text)
            }
            Divider().overlay(Brand.hairline)
            Stepper("Capo: \(capo == 0 ? "none" : "\(capo)")", value: $capo, in: 0...11)
                .foregroundStyle(Brand.text2)
            Divider().overlay(Brand.hairline)
            Stepper("Tempo: \(bpm == 0 ? "—" : "\(bpm) bpm")", value: $bpm, in: 0...260, step: 2)
                .foregroundStyle(Brand.text2)
        }
        .font(.subheadline)
        .glassCard()
    }

    private var sectionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionTitle(text: "Sections")
                Spacer()
                Button {
                    sections.append(SectionDraft(name: "Verse \(sections.count + 1)", content: "")); Haptics.tap()
                } label: { Image(systemName: "plus.circle") }
                .accessibilityLabel("Add section")
            }
            if sections.isEmpty {
                Text("Add a section, then type lyrics with chords in brackets like [G]Amazing [C]grace.")
                    .font(.caption).foregroundStyle(Brand.text3)
            }
            ForEach($sections) { $sec in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        TextField("Section name", text: $sec.name)
                            .font(.subheadline.weight(.semibold)).foregroundStyle(Brand.text)
                        Spacer()
                        Button { move(sec.id, by: -1) } label: { Image(systemName: "arrow.up") }
                            .disabled(sections.first?.id == sec.id).accessibilityLabel("Move up")
                        Button { move(sec.id, by: 1) } label: { Image(systemName: "arrow.down") }
                            .disabled(sections.last?.id == sec.id).accessibilityLabel("Move down")
                        Button(role: .destructive) { sections.removeAll { $0.id == sec.id } } label: {
                            Image(systemName: "trash")
                        }.accessibilityLabel("Delete section")
                    }
                    TextEditor(text: $sec.content)
                        .font(Brand.mono(13))
                        .frame(minHeight: 90)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                        .foregroundStyle(Brand.text)
                }
                .padding(10)
                .background(Brand.hairline.opacity(0.4), in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .glassCard()
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(text: "Performance notes")
            TextField("Intro, dynamics, cues…", text: $notes, axis: .vertical)
                .lineLimit(2...5).font(.subheadline).foregroundStyle(Brand.text)
        }.glassCard()
    }

    private func move(_ id: UUID, by delta: Int) {
        guard let i = sections.firstIndex(where: { $0.id == id }) else { return }
        let j = i + delta
        guard j >= 0, j < sections.count else { return }
        sections.swapAt(i, j); Haptics.selection()
    }

    private func load() {
        guard let s = existing else {
            if key == "C" { key = defaultKey }   // apply default for new songs
            return
        }
        title = s.title; artist = s.artist; key = s.key; bpm = s.bpm
        capo = s.capo; timeSignature = s.timeSignature; notes = s.notes
        sections = s.orderedSections.map { SectionDraft(name: $0.name, content: $0.content) }
    }

    private func save() {
        let t = title.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        let song: Song
        if let existing { song = existing } else {
            song = Song(title: t); context.insert(song)
        }
        song.title = t; song.artist = artist; song.key = key; song.bpm = bpm
        song.capo = capo; song.timeSignature = timeSignature; song.notes = notes
        // rebuild sections
        for old in song.sections { context.delete(old) }
        song.sections = []
        for (i, d) in sections.enumerated() {
            let sec = Section(name: d.name.isEmpty ? "Section \(i + 1)" : d.name, order: i, content: d.content)
            sec.song = song
            context.insert(sec)
        }
        try? context.save(); Haptics.success(); dismiss()
    }
}
