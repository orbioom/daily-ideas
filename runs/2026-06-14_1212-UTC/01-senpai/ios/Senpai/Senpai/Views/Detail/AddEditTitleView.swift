import SwiftUI
import SwiftData

/// Add or edit a title with validation (name required; total ≥ progress; etc.).
struct AddEditTitleView: View {
    enum Mode {
        case add
        case edit(Title)
    }

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @Query(sort: \Genre.name) private var allGenres: [Genre]

    let mode: Mode

    @State private var name = ""
    @State private var kind: AnimeMediaKind = .anime
    @State private var status: WatchStatus = .planning
    @State private var hasTotal = true
    @State private var totalText = ""
    @State private var progressText = "0"
    @State private var score = 0
    @State private var favorite = false
    @State private var hasSeason = false
    @State private var season: AnimeSeason = .winter
    @State private var yearText = ""
    @State private var studioOrAuthor = ""
    @State private var notes = ""
    @State private var selectedGenres: Set<String> = []

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    // MARK: Validation

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var totalValue: Int? { hasTotal ? Int(totalText) : nil }
    private var progressValue: Int { max(0, Int(progressText) ?? 0) }

    private var validationError: String? {
        if trimmedName.isEmpty { return "A title name is required." }
        if hasTotal {
            guard let total = totalValue, total > 0 else { return "Enter a valid total (1 or more)." }
            if progressValue > total { return "Progress can't exceed the total." }
        }
        if hasSeason, let y = Int(yearText) {
            if y < 1900 || y > 2100 { return "Enter a year between 1900 and 2100." }
        } else if hasSeason {
            return "Enter a valid year for the season."
        }
        return nil
    }

    private var canSave: Bool { validationError == nil }

    var body: some View {
        NavigationStack {
            Form {
                basicsSection
                progressFormSection
                seasonSection
                genresSection
                notesFormSection
                if let err = validationError {
                    Section {
                        Label(err, systemImage: "exclamationmark.triangle.fill")
                            .font(Theme.rounded(13))
                            .foregroundStyle(Theme.bad)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle(isEditing ? "Edit Title" : "New Title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }.disabled(!canSave).bold()
                }
            }
            .onAppear(perform: loadIfEditing)
        }
    }

    // MARK: Sections

    private var basicsSection: some View {
        Section("Basics") {
            TextField("Title name", text: $name)
                .font(Theme.rounded(16))
            Picker("Kind", selection: $kind) {
                ForEach(AnimeMediaKind.allCases) { k in
                    Label(k.rawValue, systemImage: k.symbol).tag(k)
                }
            }
            Picker("Status", selection: $status) {
                ForEach(WatchStatus.allCases) { s in
                    Text(s.label(for: kind)).tag(s)
                }
            }
            TextField("Studio or author", text: $studioOrAuthor)
            Toggle("Favorite", isOn: $favorite)
        }
    }

    private var progressFormSection: some View {
        Section("Progress") {
            Toggle("Known total \(kind.unitNounPlural)", isOn: $hasTotal)
            if hasTotal {
                HStack {
                    Text("Total \(kind.unitNounPlural)")
                    Spacer()
                    TextField("e.g. 12", text: $totalText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 90)
                }
            }
            HStack {
                Text("\(kind.unitNoun.capitalized)s done")
                Spacer()
                TextField("0", text: $progressText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 90)
            }
            Picker("Score", selection: $score) {
                Text("Unrated").tag(0)
                ForEach(1...10, id: \.self) { Text("\($0)").tag($0) }
            }
        }
    }

    private var seasonSection: some View {
        Section("Season") {
            Toggle("Has a season", isOn: $hasSeason)
            if hasSeason {
                Picker("Season", selection: $season) {
                    ForEach(AnimeSeason.allCases) { s in
                        Label(s.rawValue, systemImage: s.symbol).tag(s)
                    }
                }
                HStack {
                    Text("Year")
                    Spacer()
                    TextField("e.g. 2024", text: $yearText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 90)
                }
            }
        }
    }

    private var genresSection: some View {
        Section("Genres") {
            if allGenres.isEmpty {
                Text("No genres available.")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
            } else {
                ForEach(allGenres) { g in
                    Button {
                        toggleGenre(g.name)
                    } label: {
                        HStack {
                            Text(g.name).foregroundStyle(Theme.ink)
                            Spacer()
                            if selectedGenres.contains(g.name) {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Theme.accent)
                            }
                        }
                    }
                }
            }
        }
    }

    private var notesFormSection: some View {
        Section("Notes") {
            TextField("Your thoughts…", text: $notes, axis: .vertical)
                .lineLimit(3...6)
        }
    }

    // MARK: Load / save

    private func loadIfEditing() {
        guard case let .edit(title) = mode else {
            // Default new-title kind from settings when not "All".
            if let k = settings.defaultKind.kind { kind = k }
            return
        }
        name = title.name
        kind = title.kind
        status = title.status
        if let total = title.totalUnits {
            hasTotal = true
            totalText = "\(total)"
        } else {
            hasTotal = false
        }
        progressText = "\(title.progress)"
        score = title.score
        favorite = title.favorite
        if let s = title.season, let y = title.seasonYear {
            hasSeason = true
            season = s
            yearText = "\(y)"
        }
        studioOrAuthor = title.studioOrAuthor
        notes = title.notes
        selectedGenres = Set(title.genres.map(\.name))
    }

    private func toggleGenre(_ name: String) {
        if selectedGenres.contains(name) { selectedGenres.remove(name) }
        else { selectedGenres.insert(name) }
    }

    private func save() {
        guard canSave else { return }
        let total = totalValue
        let clampedProgress = total.map { min(progressValue, $0) } ?? progressValue
        let seasonYear = hasSeason ? Int(yearText) : nil

        switch mode {
        case .add:
            let title = Title(name: trimmedName,
                              kind: kind,
                              status: status,
                              totalUnits: total,
                              progress: clampedProgress,
                              score: score,
                              favorite: favorite,
                              season: hasSeason ? season : nil,
                              seasonYear: seasonYear,
                              studioOrAuthor: studioOrAuthor.trimmingCharacters(in: .whitespaces),
                              notes: notes)
            context.insert(title)
            applyGenres(to: title)
            if status == .completed { TitleActions.markCompleted(title) }
            else if status == .current, clampedProgress > 0, title.startedAt == nil { title.startedAt = .now }

        case let .edit(title):
            title.name = trimmedName
            title.kind = kind
            title.totalUnits = total
            title.progress = clampedProgress
            title.score = score
            title.favorite = favorite
            title.season = hasSeason ? season : nil
            title.seasonYear = seasonYear
            title.studioOrAuthor = studioOrAuthor.trimmingCharacters(in: .whitespaces)
            title.notes = notes
            applyGenres(to: title)
            TitleActions.setStatus(title, to: status, in: context)
        }

        try? context.save()
        Haptics.success(settings.hapticsEnabled)
        dismiss()
    }

    private func applyGenres(to title: Title) {
        let chosen = allGenres.filter { selectedGenres.contains($0.name) }
        title.genres = chosen
    }
}
