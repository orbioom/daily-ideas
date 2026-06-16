import SwiftUI
import SwiftData

/// Full detail for one concert: ticket header, rating + favorite, support acts,
/// reorderable setlist, notes, share card, edit, delete.
struct ConcertDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Bindable var concert: Concert
    let allGenres: [Genre]

    @State private var showEdit = false
    @State private var showDeleteConfirm = false
    @State private var showShareSheet = false
    @State private var shareImage: ShareableImage?
    @State private var paywallReason: PaywallReason?

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                header
                metaRow
                actionRow
                if !concert.notes.trimmingCharacters(in: .whitespaces).isEmpty { notesCard }
                detailsCard
                supportSection
                setlistSection
                deleteButton
            }
            .padding(20)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle(concert.headliner)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showEdit = true } label: { Image(systemName: "pencil") }
                    .accessibilityLabel("Edit show")
            }
        }
        .sheet(isPresented: $showEdit) {
            ConcertEditorView(concert: concert, allGenres: allGenres)
        }
        .sheet(isPresented: $showShareSheet) {
            ShareCardSheet(concert: concert)
        }
        .sheet(item: $paywallReason) { PaywallView(reason: $0) }
        .confirmationDialog("Delete this show?",
                            isPresented: $showDeleteConfirm,
                            titleVisibility: .visible) {
            Button("Delete", role: .destructive) { performDelete() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes \(concert.headliner) and its setlist. This can't be undone.")
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Theme.ticketGradient(seed: concert.colorSeed))
                    .frame(height: 120)
                VStack(spacing: 6) {
                    Image(systemName: concert.type.symbol)
                        .font(.system(size: 28, weight: .light))
                        .foregroundStyle(.white)
                    if !concert.tourName.isEmpty {
                        Text(concert.tourName)
                            .font(Theme.rounded(14, .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }
                }
                .accessibilityHidden(true)
            }
            Text(concert.date.formatted(date: .complete, time: .omitted))
                .font(Theme.rounded(15, .medium))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
            if let rating = concert.rating {
                RatingStarsDisplay(rating: rating, size: 18)
            }
        }
    }

    private var metaRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                InfoPill(text: concert.type.display, systemImage: concert.type.symbol, tint: Theme.accent)
                if !concert.locationLine.isEmpty {
                    InfoPill(text: concert.locationLine, systemImage: "mappin")
                }
                if !concert.country.isEmpty {
                    InfoPill(text: concert.country, systemImage: "globe")
                }
                ForEach(concert.sortedGenres) { g in
                    GenrePill(name: g.name, tint: g.hue)
                }
            }
        }
    }

    private var actionRow: some View {
        HStack(spacing: 12) {
            Button {
                concert.isFavorite.toggle()
                try? context.save()
                Haptics.tap(enabled: settings.hapticsEnabled)
            } label: {
                Label(concert.isFavorite ? "Favorited" : "Favorite",
                      systemImage: concert.isFavorite ? "heart.fill" : "heart")
                    .font(Theme.rounded(14, .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .fill(concert.isFavorite ? Theme.accentSoft : Theme.surface))
                    .foregroundStyle(concert.isFavorite ? Theme.accent : Theme.ink)
            }
            .accessibilityLabel(concert.isFavorite ? "Remove favorite" : "Add favorite")

            Button {
                shareCard()
            } label: {
                Label("Share memory", systemImage: "square.and.arrow.up")
                    .font(Theme.rounded(14, .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(RoundedRectangle(cornerRadius: 13, style: .continuous).fill(Theme.surface))
                    .foregroundStyle(Theme.ink)
            }
            .accessibilityHint("Creates a shareable image of this show")
        }
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Notes")
                .font(Theme.rounded(12, .bold))
                .foregroundStyle(Theme.inkFaint)
            Text(concert.notes)
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface))
    }

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !concert.companions.isEmpty {
                detailRow("Went with", concert.companions, "person.2.fill")
            }
            if !concert.seatInfo.isEmpty {
                detailRow("Seat", concert.seatInfo, "chair.fill")
            }
            if concert.ticketPrice > 0 {
                detailRow("Ticket", settings.money(concert.ticketPrice), "creditcard.fill")
            }
            if concert.companions.isEmpty && concert.seatInfo.isEmpty && concert.ticketPrice <= 0 {
                Text("No ticket details logged. Tap Edit to add seat, price, or who you went with.")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkFaint)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface))
    }

    private func detailRow(_ label: String, _ value: String, _ symbol: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 14))
                .foregroundStyle(Theme.accent)
                .frame(width: 22)
                .accessibilityHidden(true)
            Text(label)
                .font(Theme.rounded(14))
                .foregroundStyle(Theme.inkSoft)
            Spacer()
            Text(value)
                .font(Theme.rounded(14, .semibold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.trailing)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: Support

    private var supportSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(title: "Support acts", count: concert.supportActs.count)
            if concert.supportActs.isEmpty {
                emptyMini("No support acts remembered.", symbol: "person.3")
            } else {
                ForEach(Array(concert.orderedSupportActs.enumerated()), id: \.element.id) { idx, act in
                    HStack(spacing: 10) {
                        Text("\(idx + 1)")
                            .font(Theme.mono(13, .semibold))
                            .foregroundStyle(Theme.inkFaint)
                            .frame(width: 22)
                        Text(act.name)
                            .font(Theme.rounded(15, .semibold))
                            .foregroundStyle(Theme.ink)
                        Spacer()
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.surface))
                }
            }
        }
    }

    // MARK: Setlist (reorderable)

    private var setlistSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(title: "Setlist", count: concert.setlist.count)
            if concert.setlist.isEmpty {
                emptyMini("No setlist remembered. Tap Edit to add the songs you recall.", symbol: "music.note.list")
            } else {
                SetlistReorderList(concert: concert)
                    .frame(height: setlistHeight)
            }
        }
    }

    private var setlistHeight: CGFloat {
        // Each row ~ 52pt; clamp so it stays usable inside the scroll view.
        CGFloat(min(max(concert.setlist.count, 1), 30)) * 52 + 8
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            showDeleteConfirm = true
        } label: {
            Label("Delete show", systemImage: "trash")
                .font(Theme.rounded(15, .semibold))
                .foregroundStyle(Theme.bad)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.bad.opacity(0.1)))
        }
        .padding(.top, 8)
    }

    private func emptyMini(_ text: String, symbol: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: symbol).foregroundStyle(Theme.inkFaint).accessibilityHidden(true)
            Text(text).font(Theme.rounded(14)).foregroundStyle(Theme.inkSoft)
            Spacer()
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.surfaceAlt))
    }

    // MARK: Actions

    @MainActor
    private func shareCard() {
        guard isPro else {
            paywallReason = .general
            Haptics.warning(enabled: settings.hapticsEnabled)
            return
        }
        Haptics.tap(enabled: settings.hapticsEnabled)
        showShareSheet = true
    }

    private func performDelete() {
        context.delete(concert)
        try? context.save()
        Haptics.success(enabled: settings.hapticsEnabled)
        dismiss()
    }
}

/// Small section label with a count.
struct SectionLabel: View {
    let title: String
    let count: Int

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(Theme.rounded(18, .bold))
                .foregroundStyle(Theme.ink)
            Text("\(count)")
                .font(Theme.rounded(13, .semibold))
                .foregroundStyle(Theme.inkFaint)
            Spacer()
        }
    }
}

/// A reorderable List of setlist songs. Drag to reorder (active edit mode); swipe a row
/// to toggle encore / highlight (swipe actions stay live in edit mode). Saves on every change.
private struct SetlistReorderList: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @Bindable var concert: Concert

    var body: some View {
        List {
            ForEach(concert.orderedSetlist) { song in
                SetlistRow(song: song)
                    .listRowBackground(Theme.surface)
                    .listRowSeparatorTint(Theme.hairline)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button {
                            song.isHighlight.toggle()
                            try? context.save()
                            Haptics.selection(enabled: settings.hapticsEnabled)
                        } label: {
                            Label(song.isHighlight ? "Unhighlight" : "Highlight",
                                  systemImage: song.isHighlight ? "star.slash" : "star.fill")
                        }
                        .tint(Theme.gold)
                        Button {
                            song.isEncore.toggle()
                            try? context.save()
                            Haptics.selection(enabled: settings.hapticsEnabled)
                        } label: {
                            Label(song.isEncore ? "Not encore" : "Encore", systemImage: "sparkles")
                        }
                        .tint(Theme.purple)
                    }
            }
            .onMove(perform: move)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollDisabled(true)
        .environment(\.editMode, .constant(.active))
    }

    private func move(from offsets: IndexSet, to destination: Int) {
        var ordered = concert.orderedSetlist
        ordered.move(fromOffsets: offsets, toOffset: destination)
        for (i, song) in ordered.enumerated() {
            song.order = i
        }
        try? context.save()
        Haptics.selection(enabled: settings.hapticsEnabled)
    }
}

/// One setlist row showing position, title, and encore / highlight badges.
private struct SetlistRow: View {
    @Bindable var song: SetlistSong

    var body: some View {
        HStack(spacing: 10) {
            Text(song.isEncore ? "E" : "\(song.order + 1)")
                .font(Theme.mono(12, .semibold))
                .foregroundStyle(song.isEncore ? Theme.purple : Theme.inkFaint)
                .frame(width: 22)
            Text(song.title)
                .font(Theme.rounded(15, song.isHighlight ? .bold : .regular))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
            Spacer()
            if song.isHighlight {
                Image(systemName: "star.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.gold)
                    .accessibilityHidden(true)
            }
            if song.isEncore {
                Image(systemName: "sparkles")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.purple)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityHint("Swipe left to toggle encore or highlight")
    }

    private var label: String {
        var parts: [String] = []
        parts.append(song.isEncore ? "Encore: \(song.title)" : "Song \(song.order + 1): \(song.title)")
        if song.isHighlight { parts.append("highlight") }
        return parts.joined(separator: ", ")
    }
}

/// A sheet that renders and shares the memory card image.
private struct ShareCardSheet: View {
    let concert: Concert
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @State private var rendered: ShareableImage?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    MemoryCardView(concert: concert, currencyCode: settings.currencyCode)
                        .padding(.top, 12)
                    if let rendered {
                        ShareLink(item: rendered,
                                  preview: SharePreview("\(concert.headliner) — Encore",
                                                        image: Image(uiImage: rendered.image))) {
                            Label("Share image", systemImage: "square.and.arrow.up")
                                .font(Theme.rounded(16, .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.heroGradient))
                        }
                        .padding(.horizontal, 24)
                    } else {
                        ProgressView().tint(Theme.accent)
                    }
                }
                .padding(.bottom, 24)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Memory card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
            }
        }
        .task { await renderCard() }
    }

    @MainActor
    private func renderCard() {
        let card = MemoryCardView(concert: concert, currencyCode: settings.currencyCode)
        if let image = ImageExport.render(card) {
            rendered = ShareableImage(image: image)
        }
    }
}

#Preview("Concert detail") {
    NavigationStack {
        ConcertDetailView(concert: PreviewContainer.sampleConcert, allGenres: [])
            .environmentObject(AppSettings())
    }
    .modelContainer(PreviewContainer.shared)
}
