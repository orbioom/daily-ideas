import SwiftUI
import SwiftData

/// Add or edit a concert, with inline setlist + support-act editing.
/// When `concert` is nil, a new record is created on save.
struct ConcertEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false

    /// The existing record being edited, or nil for a new one.
    var concert: Concert?
    /// All genres so multi-select reuses existing objects.
    let allGenres: [Genre]

    // Form state
    @State private var headliner = ""
    @State private var date = Date()
    @State private var venueName = ""
    @State private var city = ""
    @State private var country = ""
    @State private var tourName = ""
    @State private var type: ConcertType = .concert
    @State private var status: ConcertStatus = .attended
    @State private var rating: Double?
    @State private var priceText = ""
    @State private var seatInfo = ""
    @State private var companions = ""
    @State private var notes = ""
    @State private var colorSeed = 0
    @State private var isFavorite = false
    @State private var selectedGenreNames: Set<String> = []

    // Inline children (draft rows, committed on save)
    @State private var supportDrafts: [SupportDraft] = []
    @State private var songDrafts: [SongDraft] = []
    @State private var newSupport = ""
    @State private var newSong = ""

    @State private var validationMessage: String?
    @State private var paywallReason: PaywallReason?

    private var isEditing: Bool { concert != nil }

    var body: some View {
        NavigationStack {
            Form {
                detailsSection
                statusSection
                ratingPriceSection
                genresSection
                supportSection
                setlistSection
                extrasSection
                appearanceSection
                if let validationMessage {
                    Section {
                        Label(validationMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(Theme.rounded(14))
                            .foregroundStyle(Theme.bad)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle(isEditing ? "Edit Show" : "Add Show")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    EditButton()
                    Button("Save") { save() }
                        .font(Theme.rounded(16, .semibold))
                }
            }
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
            .onAppear(perform: prefill)
        }
    }

    // MARK: Sections

    private var detailsSection: some View {
        Section("Details") {
            TextField("Headliner", text: $headliner)
                .font(Theme.rounded(17, .semibold))
            DatePicker("Date", selection: $date, displayedComponents: .date)
            TextField("Venue", text: $venueName)
            TextField("City", text: $city)
            TextField("Country", text: $country)
            TextField("Tour (optional)", text: $tourName)
        }
    }

    private var statusSection: some View {
        Section {
            Picker("Status", selection: $status) {
                ForEach(ConcertStatus.allCases) { s in
                    Label(s.display, systemImage: s.symbol).tag(s)
                }
            }
            .pickerStyle(.segmented)
            Picker("Type", selection: $type) {
                ForEach(ConcertType.allCases) { t in
                    Label(t.display, systemImage: t.symbol).tag(t)
                }
            }
            .pickerStyle(.segmented)
        } footer: {
            Text(status == .wishlist
                 ? "Wishlist shows appear on your Bucket List. Give a future date to get a live countdown."
                 : "Attended shows fill your Timeline and Stats.")
        }
    }

    private var ratingPriceSection: some View {
        Section("Rating & ticket") {
            HStack {
                Text("Rating")
                Spacer()
                RatingStarsEditor(rating: $rating, hapticsEnabled: settings.hapticsEnabled, size: 24)
            }
            HStack {
                Text(settings.currencySymbol)
                    .foregroundStyle(Theme.inkSoft)
                TextField("Ticket price", text: $priceText)
                    .keyboardType(.decimalPad)
            }
            TextField("Seat / section (optional)", text: $seatInfo)
        }
    }

    private var genresSection: some View {
        Section("Genres") {
            if allGenres.isEmpty {
                Text("Genres appear after loading sample data, or are created from the catalog.")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkFaint)
            }
            ForEach(genreOptions, id: \.name) { option in
                Button {
                    toggleGenre(named: option.name)
                } label: {
                    HStack {
                        Circle()
                            .fill(Theme.ticketColors(seed: option.seed).0)
                            .frame(width: 12, height: 12)
                        Text(option.name)
                            .foregroundStyle(Theme.ink)
                        Spacer()
                        if isGenreSelected(option.name) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Theme.accent)
                        }
                    }
                }
                .accessibilityAddTraits(isGenreSelected(option.name) ? .isSelected : [])
            }
        }
    }

    private var supportSection: some View {
        Section("Support acts") {
            if supportDrafts.isEmpty {
                Text("No support acts yet.")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkFaint)
            }
            ForEach($supportDrafts) { $draft in
                HStack {
                    Image(systemName: "line.3.horizontal")
                        .foregroundStyle(Theme.inkFaint)
                        .accessibilityHidden(true)
                    TextField("Act name", text: $draft.name)
                }
            }
            .onDelete { supportDrafts.remove(atOffsets: $0) }
            .onMove { supportDrafts.move(fromOffsets: $0, toOffset: $1) }

            HStack {
                TextField("Add support act", text: $newSupport)
                Button {
                    addSupport()
                } label: {
                    Image(systemName: "plus.circle.fill").foregroundStyle(Theme.accent)
                }
                .disabled(newSupport.trimmingCharacters(in: .whitespaces).isEmpty)
                .accessibilityLabel("Add support act")
            }
        }
    }

    private var setlistSection: some View {
        Section {
            if songDrafts.isEmpty {
                Text("No songs remembered yet. Add the ones you recall — order them, mark encores and highlights.")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkFaint)
            }
            ForEach($songDrafts) { $song in
                VStack(spacing: 6) {
                    HStack {
                        Image(systemName: "line.3.horizontal")
                            .foregroundStyle(Theme.inkFaint)
                            .accessibilityHidden(true)
                        TextField("Song title", text: $song.title)
                    }
                    HStack(spacing: 14) {
                        Toggle(isOn: $song.isEncore) {
                            Label("Encore", systemImage: "sparkles")
                                .font(Theme.rounded(12, .semibold))
                        }
                        .toggleStyle(.button)
                        .tint(Theme.purple)
                        Toggle(isOn: $song.isHighlight) {
                            Label("Highlight", systemImage: "star.fill")
                                .font(Theme.rounded(12, .semibold))
                        }
                        .toggleStyle(.button)
                        .tint(Theme.gold)
                        Spacer()
                    }
                }
            }
            .onDelete { songDrafts.remove(atOffsets: $0) }
            .onMove { songDrafts.move(fromOffsets: $0, toOffset: $1) }

            HStack {
                TextField("Add song", text: $newSong)
                Button {
                    addSong()
                } label: {
                    Image(systemName: "plus.circle.fill").foregroundStyle(Theme.accent)
                }
                .disabled(newSong.trimmingCharacters(in: .whitespaces).isEmpty)
                .accessibilityLabel("Add song")
            }
        } header: {
            HStack {
                Text("Setlist")
                Spacer()
                if !isPro {
                    Text("Free: first \(Pro.freeSetlistLimit)")
                        .font(Theme.rounded(11, .semibold))
                        .foregroundStyle(Theme.inkFaint)
                }
            }
        }
    }

    private var extrasSection: some View {
        Section("Memory") {
            TextField("Who you went with", text: $companions)
            TextField("Notes", text: $notes, axis: .vertical)
                .lineLimit(3...6)
            Toggle("Favorite", isOn: $isFavorite)
                .tint(Theme.accent)
        }
    }

    private var appearanceSection: some View {
        Section("Ticket colour") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(0..<8, id: \.self) { seed in
                        Button {
                            colorSeed = seed
                            Haptics.selection(enabled: settings.hapticsEnabled)
                        } label: {
                            Circle()
                                .fill(Theme.ticketGradient(seed: seed))
                                .frame(width: 34, height: 34)
                                .overlay(
                                    Circle().strokeBorder(Theme.ink,
                                                          lineWidth: colorSeed == seed ? 2 : 0)
                                )
                        }
                        .accessibilityLabel("Ticket colour \(seed + 1)")
                        .accessibilityAddTraits(colorSeed == seed ? .isSelected : [])
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: Genre helpers

    private struct GenreOption { let name: String; let seed: Int }

    /// Union of existing genres and the catalog so users always have choices.
    private var genreOptions: [GenreOption] {
        var seen = Set<String>()
        var options: [GenreOption] = []
        for g in allGenres.sorted(by: { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }) {
            let key = g.name.lowercased()
            guard !seen.contains(key) else { continue }
            seen.insert(key)
            options.append(GenreOption(name: g.name, seed: g.colorSeed))
        }
        for entry in GenreCatalog.all {
            let key = entry.name.lowercased()
            guard !seen.contains(key) else { continue }
            seen.insert(key)
            options.append(GenreOption(name: entry.name, seed: entry.seed))
        }
        return options
    }

    private func isGenreSelected(_ name: String) -> Bool {
        selectedGenreNames.contains(name.lowercased())
    }

    private func toggleGenre(named name: String) {
        let key = name.lowercased()
        if selectedGenreNames.contains(key) {
            selectedGenreNames.remove(key)
        } else {
            selectedGenreNames.insert(key)
        }
        Haptics.selection(enabled: settings.hapticsEnabled)
    }

    // MARK: Add rows

    private func addSupport() {
        let trimmed = newSupport.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        supportDrafts.append(SupportDraft(name: trimmed))
        newSupport = ""
        Haptics.tap(enabled: settings.hapticsEnabled)
    }

    private func addSong() {
        let trimmed = newSong.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if !Pro.canAddSong(currentCount: songDrafts.count, isPro: isPro) {
            paywallReason = .setlistLimit
            Haptics.warning(enabled: settings.hapticsEnabled)
            return
        }
        songDrafts.append(SongDraft(title: trimmed))
        newSong = ""
        Haptics.tap(enabled: settings.hapticsEnabled)
    }

    // MARK: Prefill

    private func prefill() {
        guard let c = concert else {
            // New record defaults.
            colorSeed = Int.random(in: 0..<8)
            return
        }
        headliner = c.headliner
        date = c.date
        venueName = c.venueName
        city = c.city
        country = c.country
        tourName = c.tourName
        type = c.type
        status = c.status
        rating = c.rating
        priceText = c.ticketPrice == 0 ? "" : NSDecimalNumber(decimal: c.ticketPrice).stringValue
        seatInfo = c.seatInfo
        companions = c.companions
        notes = c.notes
        colorSeed = c.colorSeed
        isFavorite = c.isFavorite
        selectedGenreNames = Set(c.genres.map { $0.name.lowercased() })
        supportDrafts = c.orderedSupportActs.map { SupportDraft(name: $0.name) }
        songDrafts = c.orderedSetlist.map {
            SongDraft(title: $0.title, isEncore: $0.isEncore, isHighlight: $0.isHighlight)
        }
    }

    // MARK: Save

    private func parsedPrice() -> Decimal {
        let cleaned = priceText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        guard !cleaned.isEmpty else { return 0 }
        let value = Decimal(string: cleaned) ?? 0
        return value < 0 ? 0 : value
    }

    private func resolveGenres() -> [Genre] {
        var result: [Genre] = []
        let existingByName = Dictionary(grouping: allGenres) { $0.name.lowercased() }
        for option in genreOptions where selectedGenreNames.contains(option.name.lowercased()) {
            if let match = existingByName[option.name.lowercased()]?.first {
                result.append(match)
            } else {
                let g = Genre(name: option.name, colorSeed: option.seed)
                context.insert(g)
                result.append(g)
            }
        }
        return result
    }

    private func save() {
        let trimmedHeadliner = headliner.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedHeadliner.isEmpty else {
            validationMessage = "Please enter the headliner."
            Haptics.error(enabled: settings.hapticsEnabled)
            return
        }
        validationMessage = nil

        let target: Concert
        if let existing = concert {
            target = existing
        } else {
            target = Concert(headliner: trimmedHeadliner, date: date)
            context.insert(target)
        }

        target.headliner = trimmedHeadliner
        target.date = date
        target.venueName = venueName.trimmingCharacters(in: .whitespacesAndNewlines)
        target.city = city.trimmingCharacters(in: .whitespacesAndNewlines)
        target.country = country.trimmingCharacters(in: .whitespacesAndNewlines)
        target.tourName = tourName.trimmingCharacters(in: .whitespacesAndNewlines)
        target.type = type
        target.status = status
        target.rating = rating
        target.ticketPrice = parsedPrice()
        target.seatInfo = seatInfo.trimmingCharacters(in: .whitespacesAndNewlines)
        target.companions = companions.trimmingCharacters(in: .whitespacesAndNewlines)
        target.notes = notes
        target.colorSeed = colorSeed
        target.isFavorite = isFavorite
        target.genres = resolveGenres()

        // Replace children with the current drafts (cascade deletes the old ones).
        for old in target.supportActs { context.delete(old) }
        target.supportActs.removeAll()
        for (i, draft) in supportDrafts.enumerated() {
            let trimmed = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            let act = SupportAct(order: i, name: trimmed)
            act.concert = target
            target.supportActs.append(act)
        }

        for old in target.setlist { context.delete(old) }
        target.setlist.removeAll()
        for (i, draft) in songDrafts.enumerated() {
            let trimmed = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            let song = SetlistSong(order: i, title: trimmed,
                                   isEncore: draft.isEncore, isHighlight: draft.isHighlight)
            song.concert = target
            target.setlist.append(song)
        }

        try? context.save()
        Haptics.success(enabled: settings.hapticsEnabled)
        dismiss()
    }
}

// MARK: - Draft row models

struct SupportDraft: Identifiable {
    let id = UUID()
    var name: String
}

struct SongDraft: Identifiable {
    let id = UUID()
    var title: String
    var isEncore: Bool = false
    var isHighlight: Bool = false
}
