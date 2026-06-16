import SwiftUI
import SwiftData

/// Add a new Title, or edit an existing one. Enforces the free-tier title cap on add.
struct TitleEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false

    /// nil = adding new.
    let existing: Title?
    /// Current library count, used to enforce the free cap when adding.
    let currentTitleCount: Int

    @State private var name = ""
    @State private var yearText = ""
    @State private var kind: TitleKind = .movie
    @State private var selectedGenres: Set<Genre> = []
    @State private var runtimeText = ""
    @State private var creator = ""
    @State private var status: WatchStatus = .watchlist
    @State private var synopsis = ""
    @State private var totalEpisodesText = ""
    @State private var totalSeasonsText = ""

    @State private var validationMessage: String?
    @State private var showPaywall = false

    private var isEditing: Bool { existing != nil }

    var body: some View {
        NavigationStack {
            Form {
                basics
                if kind.isShow { showFields }
                genreSection
                detailsSection
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
            .navigationTitle(isEditing ? "Edit Title" : "Add Title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }.fontWeight(.semibold)
                }
            }
            .onAppear(perform: load)
            .sheet(isPresented: $showPaywall) {
                PaywallView(reason: .titleLimit)
            }
        }
    }

    private var basics: some View {
        Section("Basics") {
            TextField("Title", text: $name)
                .font(Theme.rounded(17))
            Picker("Kind", selection: $kind) {
                ForEach(TitleKind.allCases) { k in
                    Label(k.displayName, systemImage: k.systemImage).tag(k)
                }
            }
            .pickerStyle(.segmented)
            HStack {
                Text("Year")
                Spacer()
                TextField("2024", text: $yearText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 90)
            }
            HStack {
                Text(kind.isShow ? "Minutes / episode" : "Runtime (min)")
                Spacer()
                TextField("0", text: $runtimeText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 90)
            }
        }
    }

    private var showFields: some View {
        Section("Show") {
            HStack {
                Text("Total episodes")
                Spacer()
                TextField("0", text: $totalEpisodesText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 90)
            }
            HStack {
                Text("Total seasons")
                Spacer()
                TextField("0", text: $totalSeasonsText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 90)
            }
        }
    }

    private var genreSection: some View {
        Section("Genres") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 8)], spacing: 8) {
                ForEach(Genre.allCases) { genre in
                    genreChip(genre)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func genreChip(_ genre: Genre) -> some View {
        let selected = selectedGenres.contains(genre)
        return Button {
            if selected { selectedGenres.remove(genre) } else { selectedGenres.insert(genre) }
            Haptics.selection(enabled: settings.hapticsEnabled)
        } label: {
            Text(genre.displayName)
                .font(Theme.rounded(13, .semibold))
                .foregroundStyle(selected ? .white : Theme.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    Capsule().fill(selected ? Theme.accent : Theme.surfaceAlt)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(genre.displayName)
        .accessibilityValue(selected ? "Selected" : "Not selected")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var detailsSection: some View {
        Section("Details") {
            Picker("Status", selection: $status) {
                ForEach(WatchStatus.allCases) { s in
                    Label(s.displayName, systemImage: s.systemImage).tag(s)
                }
            }
            TextField(kind.isShow ? "Showrunner" : "Director", text: $creator)
            TextField("Synopsis (optional)", text: $synopsis, axis: .vertical)
                .lineLimit(3...6)
        }
    }

    // MARK: - Load / Save

    private func load() {
        guard let existing else { return }
        name = existing.name
        yearText = String(existing.year)
        kind = existing.kind
        selectedGenres = Set(existing.genres)
        runtimeText = existing.runtimeMinutes > 0 ? String(existing.runtimeMinutes) : ""
        creator = existing.creator
        status = existing.status
        synopsis = existing.synopsis
        totalEpisodesText = existing.totalEpisodes > 0 ? String(existing.totalEpisodes) : ""
        totalSeasonsText = existing.totalSeasons > 0 ? String(existing.totalSeasons) : ""
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            fail("Give your title a name.")
            return
        }
        guard let year = Int(yearText.trimmingCharacters(in: .whitespaces)), year > 1800, year < 2200 else {
            fail("Enter a valid year, like 2024.")
            return
        }
        let runtime = Int(runtimeText.trimmingCharacters(in: .whitespaces)) ?? 0
        let totalEps = kind.isShow ? (Int(totalEpisodesText.trimmingCharacters(in: .whitespaces)) ?? 0) : 0
        let totalSeasons = kind.isShow ? (Int(totalSeasonsText.trimmingCharacters(in: .whitespaces)) ?? 0) : 0
        let genres = selectedGenres.map { $0.rawValue }.sorted()

        if let existing {
            existing.name = trimmedName
            existing.year = year
            existing.kind = kind
            existing.genresRaw = genres
            existing.runtimeMinutes = max(0, runtime)
            existing.creator = creator.trimmingCharacters(in: .whitespaces)
            existing.status = status
            existing.synopsis = synopsis.trimmingCharacters(in: .whitespacesAndNewlines)
            existing.totalEpisodes = max(0, totalEps)
            existing.totalSeasons = max(0, totalSeasons)
            // Keep watchedEpisodes within bounds if total shrank.
            if existing.totalEpisodes > 0 {
                existing.watchedEpisodes = min(existing.watchedEpisodes, existing.totalEpisodes)
            }
        } else {
            // Enforce the free cap on add.
            guard Pro.canAddTitle(currentCount: currentTitleCount, isPro: isPro) else {
                showPaywall = true
                Haptics.warning(enabled: settings.hapticsEnabled)
                return
            }
            let title = Title(name: trimmedName,
                              year: year,
                              kind: kind,
                              genres: genres,
                              synopsis: synopsis.trimmingCharacters(in: .whitespacesAndNewlines),
                              runtimeMinutes: max(0, runtime),
                              creator: creator.trimmingCharacters(in: .whitespaces),
                              status: status,
                              colorSeed: Int.random(in: 0...9_999),
                              totalEpisodes: max(0, totalEps),
                              totalSeasons: max(0, totalSeasons))
            context.insert(title)
        }
        try? context.save()
        Haptics.success(enabled: settings.hapticsEnabled)
        dismiss()
    }

    private func fail(_ message: String) {
        validationMessage = message
        Haptics.error(enabled: settings.hapticsEnabled)
    }
}

#Preview {
    TitleEditorView(existing: nil, currentTitleCount: 0)
        .environmentObject(AppSettings())
        .modelContainer(PreviewContainer.empty)
}
