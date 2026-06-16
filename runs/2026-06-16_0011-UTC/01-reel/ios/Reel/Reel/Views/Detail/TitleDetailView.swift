import SwiftUI
import SwiftData

/// Full detail for a Title: generated poster header, metadata, status & rating controls,
/// episode tracker (shows), diary entries, and edit/delete.
struct TitleDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @Bindable var title: Title

    @State private var showLogSheet = false
    @State private var editingEntry: DiaryEntry?
    @State private var showEditSheet = false
    @State private var showDeleteConfirm = false
    @State private var spoilersRevealed = false

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                heroHeader
                statusControl
                ratingControl
                if title.kind.isShow { episodeTracker }
                if !title.synopsis.isEmpty { synopsisCard }
                diarySection
                deleteButton
            }
            .padding(20)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle(title.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    title.isFavorite.toggle()
                    try? context.save()
                    Haptics.tap(enabled: settings.hapticsEnabled)
                } label: {
                    Image(systemName: title.isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(title.isFavorite ? Theme.accent : Theme.inkSoft)
                }
                .accessibilityLabel(title.isFavorite ? "Remove from favorites" : "Add to favorites")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showEditSheet = true
                } label: {
                    Image(systemName: "square.and.pencil")
                }
                .accessibilityLabel("Edit title")
            }
        }
        .sheet(isPresented: $showLogSheet) {
            DiaryEntryEditorView(title: title, existing: nil)
        }
        .sheet(item: $editingEntry) { entry in
            DiaryEntryEditorView(title: title, existing: entry)
        }
        .sheet(isPresented: $showEditSheet) {
            TitleEditorView(existing: title, currentTitleCount: 0)
        }
        .confirmationDialog("Delete this title?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete \(title.name)", role: .destructive) { deleteTitle() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently removes the title and all \(title.entries.count) of its diary entries.")
        }
    }

    // MARK: Header

    private var heroHeader: some View {
        VStack(spacing: 14) {
            PosterView(title: title, asGradient: settings.showPostersAsGradient, showOverlay: false, cornerRadius: 18)
                .frame(width: 150, height: 222)
                .shadow(color: .black.opacity(0.18), radius: 14, y: 8)
            VStack(spacing: 6) {
                Text(title.name)
                    .font(Theme.serif(24, .bold))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                Text("\(String(title.year)) · \(title.kind.displayName) · \(title.runtimeLabel)")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
                if !title.creator.isEmpty {
                    Text(title.kind.isShow ? "Created by \(title.creator)" : "Directed by \(title.creator)")
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkFaint)
                }
                if !title.genres.isEmpty {
                    genrePills
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var genrePills: some View {
        FlowChips(items: title.genres.map { $0.displayName })
            .padding(.top, 4)
    }

    // MARK: Status

    private var statusControl: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Status", systemImage: "flag")
            Picker("Status", selection: Binding(
                get: { title.status },
                set: { newValue in
                    title.status = newValue
                    try? context.save()
                    Haptics.selection(enabled: settings.hapticsEnabled)
                }
            )) {
                ForEach(WatchStatus.allCases) { s in
                    Text(s.displayName).tag(s)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(16)
        .cardSurface()
    }

    // MARK: Rating

    private var ratingControl: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Your rating", systemImage: "star")
            HStack {
                StarRatingControl(rating: Binding(
                    get: { title.rating ?? 0 },
                    set: { newValue in
                        title.rating = newValue > 0 ? newValue : nil
                        try? context.save()
                        Haptics.tap(enabled: settings.hapticsEnabled)
                    }
                ), size: 30)
                Spacer()
                Text(title.rating != nil ? String(format: "%.1f", title.rating ?? 0) : "Not rated")
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(Theme.inkSoft)
            }
        }
        .padding(16)
        .cardSurface()
    }

    // MARK: Episode tracker (shows)

    private var episodeTracker: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Episodes", systemImage: "tv")
            HStack {
                Text("\(title.watchedEpisodes) / \(title.totalEpisodes > 0 ? String(title.totalEpisodes) : "?") watched")
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(Theme.ink)
                Spacer()
                if title.totalSeasons > 0 {
                    Text("\(title.totalSeasons) season\(title.totalSeasons == 1 ? "" : "s")")
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkSoft)
                }
            }
            if title.totalEpisodes > 0 {
                ProgressView(value: title.episodeProgress)
                    .tint(Theme.accent)
                    .accessibilityLabel("Episode progress")
                    .accessibilityValue("\(Int(title.episodeProgress * 100)) percent")
            }
            HStack(spacing: 10) {
                Button {
                    decrementEpisode()
                } label: {
                    Label("Minus one", systemImage: "minus")
                        .font(Theme.rounded(15, .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .foregroundStyle(Theme.ink)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.surfaceAlt))
                }
                .buttonStyle(PressableScale())
                .accessibilityLabel("Mark one fewer episode watched")

                Button {
                    incrementEpisode()
                } label: {
                    Label("Plus one", systemImage: "plus")
                        .font(Theme.rounded(15, .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .foregroundStyle(.white)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.accent))
                }
                .buttonStyle(PressableScale())
                .accessibilityLabel("Mark one more episode watched")
            }
        }
        .padding(16)
        .cardSurface()
    }

    // MARK: Synopsis

    private var synopsisCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Synopsis", systemImage: "text.alignleft")
            Text(title.synopsis)
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
                .blur(radius: shouldBlurSynopsis ? 6 : 0)
                .overlay {
                    if shouldBlurSynopsis {
                        Button("Tap to reveal synopsis") {
                            withAnimation { spoilersRevealed = true }
                        }
                        .font(Theme.rounded(13, .semibold))
                        .foregroundStyle(Theme.accent)
                    }
                }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .cardSurface()
    }

    private var shouldBlurSynopsis: Bool {
        settings.hideSpoilers && !spoilersRevealed
    }

    // MARK: Diary entries

    private var diarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeader(title: "Diary", systemImage: "book")
                Text("\(title.entries.count)")
                    .font(Theme.rounded(13, .semibold))
                    .foregroundStyle(Theme.inkSoft)
            }
            if sortedEntries.isEmpty {
                Text("No watches logged yet. Tap below to add the first.")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ForEach(sortedEntries) { entry in
                    Button {
                        editingEntry = entry
                    } label: {
                        DiaryEntryRow(entry: entry, hideSpoilers: settings.hideSpoilers)
                    }
                    .buttonStyle(.plain)
                }
            }
            PrimaryButton(title: "Log a watch", systemImage: "plus.circle.fill") {
                showLogSheet = true
            }
            .padding(.top, 4)
        }
        .padding(16)
        .cardSurface()
    }

    private var sortedEntries: [DiaryEntry] {
        title.entries.sorted { $0.watchedDate > $1.watchedDate }
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            showDeleteConfirm = true
        } label: {
            Label("Delete title", systemImage: "trash")
                .font(Theme.rounded(15, .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .foregroundStyle(Theme.bad)
                .background(RoundedRectangle(cornerRadius: Theme.corner, style: .continuous).fill(Theme.bad.opacity(0.12)))
        }
    }

    // MARK: Actions

    private func incrementEpisode() {
        let cap = title.totalEpisodes > 0 ? title.totalEpisodes : title.watchedEpisodes + 1
        title.watchedEpisodes = min(cap, title.watchedEpisodes + 1)
        if title.status == .watchlist { title.status = .watching }
        if title.totalEpisodes > 0 && title.watchedEpisodes >= title.totalEpisodes {
            title.status = .watched
        }
        try? context.save()
        Haptics.tap(enabled: settings.hapticsEnabled)
    }

    private func decrementEpisode() {
        guard title.watchedEpisodes > 0 else { return }
        title.watchedEpisodes -= 1
        if title.watchedEpisodes == 0 && title.status == .watched {
            title.status = .watching
        }
        try? context.save()
        Haptics.tap(enabled: settings.hapticsEnabled)
    }

    private func deleteTitle() {
        context.delete(title)
        try? context.save()
        Haptics.warning(enabled: settings.hapticsEnabled)
        dismiss()
    }
}

/// A single diary entry row.
struct DiaryEntryRow: View {
    let entry: DiaryEntry
    var hideSpoilers: Bool = false
    @State private var revealed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(entry.watchedDate.formatted(date: .abbreviated, time: .omitted))
                    .font(Theme.rounded(13, .semibold))
                    .foregroundStyle(Theme.ink)
                if entry.isRewatch {
                    Label("Rewatch", systemImage: "arrow.triangle.2.circlepath")
                        .font(Theme.rounded(11, .semibold))
                        .foregroundStyle(Theme.accent)
                        .labelStyle(.titleAndIcon)
                }
                Spacer()
                if entry.rating > 0 {
                    StarsView(rating: entry.rating, size: 12)
                }
            }
            if !entry.review.isEmpty {
                Text(entry.review)
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                    .blur(radius: shouldBlur ? 5 : 0)
                    .onTapGesture { if shouldBlur { withAnimation { revealed = true } } }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.surfaceAlt))
        .accessibilityElement(children: .combine)
    }

    private var shouldBlur: Bool { hideSpoilers && !revealed }
}

/// A simple wrapping row of small chips (genres).
struct FlowChips: View {
    let items: [String]

    var body: some View {
        // A lightweight wrap using a fixed-row HStack inside a flexible layout.
        FlexibleWrap(items: items) { item in
            Text(item)
                .font(Theme.rounded(12, .semibold))
                .foregroundStyle(Theme.inkSoft)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(Theme.surfaceAlt))
        }
    }
}

#Preview {
    let title = Title(name: "Blade Runner 2049", year: 2017, kind: .movie,
                      genres: [Genre.sciFi.rawValue, Genre.drama.rawValue],
                      synopsis: "A new blade runner unearths a long-buried secret.",
                      runtimeMinutes: 164, creator: "Denis Villeneuve",
                      status: .watched, rating: 4.5, colorSeed: 6)
    return NavigationStack {
        TitleDetailView(title: title)
    }
    .environmentObject(AppSettings())
    .modelContainer(PreviewContainer.empty)
}
