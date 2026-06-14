import SwiftUI
import SwiftData

/// A draft track row used by the inline editor before commit.
private struct DraftTrack: Identifiable {
    let id = UUID()
    var side: String
    var title: String
    var durationText: String   // "m:ss" or seconds
}

/// Add or edit a record, including an inline tracklist editor. Validates required fields.
struct RecordEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    /// nil = adding new.
    let record: Record?
    let initialStatus: RecordStatus

    @State private var title = ""
    @State private var artist = ""
    @State private var yearText = ""
    @State private var format: Format = .lp
    @State private var speed: Speed = .rpm33
    @State private var genre: Genre = .rock
    @State private var label = ""
    @State private var catalogNo = ""
    @State private var media: Grade = .nearMint
    @State private var sleeve: Grade = .nearMint
    @State private var paidText = ""
    @State private var valueText = ""
    @State private var vinylColor = "Black"
    @State private var status: RecordStatus = .owned
    @State private var notes = ""
    @State private var drafts: [DraftTrack] = []
    @State private var validationMessage: String?

    private var isEditing: Bool { record != nil }
    private let colorOptions = ["Black", "Clear", "White", "Red", "Blue", "Green", "Splatter", "Marble", "Gold", "Picture Disc"]
    private let sideOptions = ["A", "B", "C", "D"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Album") {
                    TextField("Title", text: $title)
                    TextField("Artist", text: $artist)
                    TextField("Year", text: $yearText)
                        .keyboardType(.numberPad)
                }
                Section("Pressing") {
                    Picker("Format", selection: $format) {
                        ForEach(Format.allCases) { f in Text(f.display).tag(f) }
                    }
                    Picker("Speed", selection: $speed) {
                        ForEach(Speed.allCases) { s in Text(s.display).tag(s) }
                    }
                    Picker("Genre", selection: $genre) {
                        ForEach(Genre.allCases) { g in Text(g.rawValue).tag(g) }
                    }
                    Picker("Vinyl color", selection: $vinylColor) {
                        ForEach(colorOptions, id: \.self) { c in Text(c).tag(c) }
                    }
                    TextField("Label", text: $label)
                    TextField("Catalog #", text: $catalogNo)
                }
                Section("Status") {
                    Picker("Status", selection: $status) {
                        ForEach(RecordStatus.allCases) { s in Text(s.display).tag(s) }
                    }
                    .pickerStyle(.segmented)
                }
                Section("Condition") {
                    Picker("Media", selection: $media) {
                        ForEach(Grade.allCases) { g in Text(g.display).tag(g) }
                    }
                    Picker("Sleeve", selection: $sleeve) {
                        ForEach(Grade.allCases) { g in Text(g.display).tag(g) }
                    }
                }
                Section("Value") {
                    moneyField("Price paid", $paidText)
                    moneyField("Est. value", $valueText)
                }
                tracklistSection
                Section("Notes") {
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                if let validationMessage {
                    Section {
                        Label(validationMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(Theme.rounded(14)).foregroundStyle(Theme.bad)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Record" : "Add Record")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }.fontWeight(.semibold)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func moneyField(_ title: String, _ text: Binding<String>) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(settings.currencySymbol.isEmpty ? "$" : settings.currencySymbol)
                .foregroundStyle(Theme.inkSoft)
            TextField("0.00", text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 90)
        }
    }

    private var tracklistSection: some View {
        Section {
            if drafts.isEmpty {
                Text("No tracks yet. Add tracks per side below.")
                    .font(Theme.rounded(13)).foregroundStyle(Theme.inkSoft)
            }
            ForEach($drafts) { $draft in
                VStack(spacing: 6) {
                    HStack {
                        Picker("Side", selection: $draft.side) {
                            ForEach(sideOptions, id: \.self) { s in Text(s).tag(s) }
                        }
                        .labelsHidden()
                        .frame(width: 64)
                        TextField("Track title", text: $draft.title)
                        TextField("m:ss", text: $draft.durationText)
                            .keyboardType(.numbersAndPunctuation)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 56)
                    }
                }
            }
            .onDelete { idx in drafts.remove(atOffsets: idx) }
            .onMove { from, to in drafts.move(fromOffsets: from, toOffset: to) }

            Button { addTrack() } label: {
                Label("Add track", systemImage: "plus.circle")
            }
        } header: {
            HStack {
                Text("Tracklist")
                Spacer()
                if !drafts.isEmpty {
                    EditButton().font(Theme.rounded(13))
                }
            }
        } footer: {
            Text("Set the side (A/B/C/D), title, and an optional duration like 3:24.")
        }
    }

    // MARK: Load

    private func load() {
        if let record {
            title = record.title
            artist = record.artist
            if let y = record.year, y > 0 { yearText = String(y) }
            format = record.format
            speed = record.speed
            genre = record.genre
            label = record.label
            catalogNo = record.catalogNo
            media = record.mediaCondition
            sleeve = record.sleeveCondition
            if record.pricePaid > 0 { paidText = String(format: "%.2f", record.pricePaid) }
            if record.estValue > 0 { valueText = String(format: "%.2f", record.estValue) }
            vinylColor = colorOptions.contains(record.vinylColor) ? record.vinylColor : "Black"
            status = record.status
            notes = record.notes
            drafts = record.tracks
                .sorted { ($0.side, $0.position) < ($1.side, $1.position) }
                .map { DraftTrack(side: $0.side, title: $0.title,
                                  durationText: $0.seconds > 0 ? $0.durationLabel : "") }
        } else {
            status = initialStatus
        }
    }

    private func addTrack() {
        let lastSide = drafts.last?.side ?? "A"
        drafts.append(DraftTrack(side: lastSide, title: "", durationText: ""))
        Haptics.tap(settings.hapticsEnabled)
    }

    // MARK: Save

    private func parsedMoney(_ raw: String) -> Double? {
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return 0 }
        return Double(trimmed.replacingOccurrences(of: ",", with: "."))
    }

    private func save() {
        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let a = artist.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return fail("Give the album a title.") }
        guard !a.isEmpty else { return fail("Add the artist.") }

        var year: Int? = nil
        let yearTrim = yearText.trimmingCharacters(in: .whitespaces)
        if !yearTrim.isEmpty {
            guard let y = Int(yearTrim), y >= 1900, y <= 2100 else {
                return fail("Enter a year between 1900 and 2100, or leave it blank.")
            }
            year = y
        }

        guard let paid = parsedMoney(paidText), paid >= 0 else {
            return fail("Price paid must be a number ≥ 0.")
        }
        guard let value = parsedMoney(valueText), value >= 0 else {
            return fail("Estimated value must be a number ≥ 0.")
        }

        // Validate any non-empty duration fields.
        for d in drafts where !d.title.trimmingCharacters(in: .whitespaces).isEmpty {
            if Fmt.parseDuration(d.durationText) == nil {
                return fail("Check durations — use m:ss like 3:24, or leave blank.")
            }
        }

        let target: Record
        if let record {
            target = record
        } else {
            target = Record(title: t, artist: a, genre: genre)
            context.insert(target)
        }

        target.title = t
        target.artist = a
        target.year = year
        target.format = format
        target.speed = speed
        target.genre = genre
        target.label = label.trimmingCharacters(in: .whitespaces)
        target.catalogNo = catalogNo.trimmingCharacters(in: .whitespaces)
        target.mediaCondition = media
        target.sleeveCondition = sleeve
        target.pricePaid = paid
        target.estValue = value
        target.vinylColor = vinylColor
        target.status = status
        target.notes = notes

        applyTracks(to: target)

        try? context.save()
        Haptics.success(settings.hapticsEnabled)
        dismiss()
    }

    /// Replace the record's tracks with the current drafts (skipping empty titles).
    private func applyTracks(to rec: Record) {
        for existing in rec.tracks { context.delete(existing) }
        rec.tracks.removeAll()

        var sidePositions: [String: Int] = [:]
        for d in drafts {
            let title = d.title.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !title.isEmpty else { continue }
            let side = sideOptions.contains(d.side) ? d.side : "A"
            let pos = (sidePositions[side] ?? 0) + 1
            sidePositions[side] = pos
            let seconds = Fmt.parseDuration(d.durationText) ?? 0
            let track = Track(side: side, position: pos, title: title, seconds: seconds)
            track.record = rec
            rec.tracks.append(track)
        }
    }

    private func fail(_ message: String) {
        validationMessage = message
        Haptics.error(settings.hapticsEnabled)
    }
}
