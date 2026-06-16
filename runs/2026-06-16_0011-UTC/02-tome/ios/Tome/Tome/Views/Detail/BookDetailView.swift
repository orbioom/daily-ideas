import SwiftUI
import SwiftData

/// Full detail for a book: cover header, progress, sessions, rating, shelf, review.
struct BookDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    @Bindable var book: Book

    @State private var showEdit = false
    @State private var showLogSession = false
    @State private var showUpdateProgress = false
    @State private var showDeleteConfirm = false
    @State private var reviewDraft = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                header
                metaRow
                progressCard
                actionRow
                shelfPicker
                ratingCard
                reviewCard
                sessionsSection
                deleteButton
            }
            .padding(20)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle(book.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    book.isFavorite.toggle()
                    try? context.save()
                    Haptics.tap(enabled: settings.hapticsEnabled)
                } label: {
                    Image(systemName: book.isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(book.isFavorite ? Theme.accent : Theme.inkSoft)
                }
                .accessibilityLabel(book.isFavorite ? "Remove favorite" : "Add favorite")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { showEdit = true } label: { Image(systemName: "pencil") }
                    .accessibilityLabel("Edit book")
            }
        }
        .sheet(isPresented: $showEdit) { AddEditBookView(book: book) }
        .sheet(isPresented: $showLogSession) { LogSessionView(book: book) }
        .sheet(isPresented: $showUpdateProgress) { UpdateProgressView(book: book) }
        .confirmationDialog("Delete \(book.title)?",
                            isPresented: $showDeleteConfirm,
                            titleVisibility: .visible) {
            Button("Delete", role: .destructive) { performDelete() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the book and all its reading sessions. This can't be undone.")
        }
        .onAppear { reviewDraft = book.review }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 12) {
            BookCover(title: book.title,
                      author: book.author,
                      colorSeed: book.colorSeed,
                      initials: book.coverInitials,
                      asGradient: settings.showCoversAsGradient)
                .frame(width: 150)
                .shadow(color: .black.opacity(0.18), radius: 12, y: 6)
            Text(book.title)
                .font(Theme.serif(24, .bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text(book.author)
                .font(Theme.rounded(16))
                .foregroundStyle(Theme.inkSoft)
            if let series = book.seriesLabel {
                Pill(text: series, systemImage: "books.vertical", tint: Theme.accent)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
    }

    private var metaRow: some View {
        HStack(spacing: 8) {
            Pill(text: book.shelf.shortName, systemImage: book.shelf.symbol, tint: book.shelf.tint)
            Pill(text: book.format.displayName, systemImage: book.format.symbol)
            Pill(text: "\(book.pageCount) pp", systemImage: "doc.text")
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Progress

    private var progressCard: some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Progress")
                        .font(Theme.rounded(13, .semibold))
                        .foregroundStyle(Theme.inkSoft)
                    Text("Page \(book.currentPage) of \(book.pageCount)")
                        .font(Theme.rounded(17, .bold))
                        .foregroundStyle(Theme.ink)
                        .monospacedDigit()
                }
                Spacer()
                ProgressRing(progress: book.progress, lineWidth: 8,
                             label: "\(Int(book.progress * 100))%")
                    .frame(width: 56, height: 56)
            }
            ProgressView(value: book.progress)
                .tint(Theme.accent)
            if let projection = projectionText {
                Label(projection, systemImage: "calendar.badge.clock")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .cardSurface()
    }

    private var projectionText: String? {
        guard book.shelf == .reading else { return nil }
        let pace = ReadingEngine.pace(for: book.sessions)
        guard let date = ReadingEngine.projectedFinish(pagesRemaining: book.pagesRemaining, pace: pace) else {
            return book.pagesRemaining > 0 ? "Log a few sessions to project your finish date." : nil
        }
        let perDay = Int(pace.rounded())
        return "About \(perDay) pp/day — finishing around \(date.formatted(date: .abbreviated, time: .omitted))"
    }

    private var actionRow: some View {
        HStack(spacing: 12) {
            actionButton(title: "Update page", symbol: "slider.horizontal.3", filled: false) {
                showUpdateProgress = true
                Haptics.tap(enabled: settings.hapticsEnabled)
            }
            actionButton(title: "Log session", symbol: "plus.circle.fill", filled: true) {
                showLogSession = true
                Haptics.tap(enabled: settings.hapticsEnabled)
            }
        }
    }

    private func actionButton(title: String, symbol: String, filled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(Theme.rounded(14, .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .foregroundStyle(filled ? .white : Theme.accent)
                .background(
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .fill(filled ? AnyShapeStyle(Theme.heroGradient) : AnyShapeStyle(Theme.accentSoft))
                )
        }
        .buttonStyle(PressableScale())
    }

    // MARK: - Shelf

    private var shelfPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Shelf")
                .font(Theme.rounded(13, .semibold))
                .foregroundStyle(Theme.inkSoft)
            Picker("Shelf", selection: shelfBinding) {
                ForEach(Shelf.allCases) { s in
                    Text(s.shortName).tag(s)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(16)
        .cardSurface()
    }

    private var shelfBinding: Binding<Shelf> {
        Binding(
            get: { book.shelf },
            set: { newShelf in
                applyShelfChange(to: newShelf)
            }
        )
    }

    /// Moving shelves auto-sets started/finished dates.
    private func applyShelfChange(to newShelf: Shelf) {
        let old = book.shelf
        guard old != newShelf else { return }
        book.shelf = newShelf
        switch newShelf {
        case .reading:
            if book.startedDate == nil { book.startedDate = .now }
            book.finishedDate = nil
        case .finished:
            if book.startedDate == nil { book.startedDate = .now }
            book.finishedDate = .now
            book.currentPage = book.pageCount
        case .wantToRead:
            book.startedDate = nil
            book.finishedDate = nil
            book.currentPage = 0
        case .dnf:
            if book.startedDate == nil { book.startedDate = .now }
            book.finishedDate = nil
        }
        try? context.save()
        Haptics.selection(enabled: settings.hapticsEnabled)
    }

    // MARK: - Rating

    private var ratingCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Your rating")
                .font(Theme.rounded(13, .semibold))
                .foregroundStyle(Theme.inkSoft)
            StarRatingPicker(rating: ratingBinding, hapticsEnabled: settings.hapticsEnabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .cardSurface()
    }

    private var ratingBinding: Binding<Double> {
        Binding(
            get: { book.rating ?? 0 },
            set: { newValue in
                book.rating = newValue > 0 ? newValue : nil
                try? context.save()
            }
        )
    }

    // MARK: - Review

    private var reviewCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Review & notes")
                .font(Theme.rounded(13, .semibold))
                .foregroundStyle(Theme.inkSoft)
            TextField("What did you think?", text: $reviewDraft, axis: .vertical)
                .font(Theme.rounded(15))
                .lineLimit(3...8)
                .onChange(of: reviewDraft) { _, newValue in
                    book.review = newValue
                    try? context.save()
                }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .cardSurface()
    }

    // MARK: - Sessions

    private var sessionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Reading sessions")
                    .font(Theme.serif(20, .semibold))
                    .foregroundStyle(Theme.ink)
                Text("\(book.sessions.count)")
                    .font(Theme.rounded(13, .semibold))
                    .foregroundStyle(Theme.inkFaint)
                Spacer()
                Button {
                    showLogSession = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Theme.accent)
                }
                .accessibilityLabel("Add reading session")
            }
            if book.sessions.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "clock").foregroundStyle(Theme.inkFaint)
                    Text("No sessions logged yet.")
                        .font(Theme.rounded(14)).foregroundStyle(Theme.inkSoft)
                    Spacer()
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.surfaceAlt))
            } else {
                ForEach(book.sessions.sorted { $0.date > $1.date }) { session in
                    sessionRow(session)
                }
            }
        }
    }

    private func sessionRow(_ session: ReadingSession) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "book.pages")
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(session.date.formatted(date: .abbreviated, time: .omitted))
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(Theme.ink)
                Text("\(session.pagesRead) pages · \(session.minutes) min")
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkSoft)
            }
            Spacer()
            Button(role: .destructive) {
                deleteSession(session)
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.bad)
            }
            .accessibilityLabel("Delete session")
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.surface))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Theme.hairline, lineWidth: 1))
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            showDeleteConfirm = true
        } label: {
            Label("Delete book", systemImage: "trash")
                .font(Theme.rounded(15, .semibold))
                .foregroundStyle(Theme.bad)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.bad.opacity(0.1)))
        }
        .padding(.top, 8)
    }

    // MARK: - Actions

    private func deleteSession(_ session: ReadingSession) {
        book.sessions.removeAll { $0.id == session.id }
        context.delete(session)
        try? context.save()
        Haptics.tap(enabled: settings.hapticsEnabled)
    }

    private func performDelete() {
        context.delete(book)
        try? context.save()
        Haptics.success(enabled: settings.hapticsEnabled)
        dismiss()
    }
}
