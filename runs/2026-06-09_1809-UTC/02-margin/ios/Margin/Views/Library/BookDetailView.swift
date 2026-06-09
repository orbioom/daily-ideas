import SwiftUI
import SwiftData

/// Detail screen for a single book: header, progress, editable rating, tags,
/// session history, and actions (log progress, mark finished, edit, delete).
struct BookDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var book: Book

    @State private var showLog = false
    @State private var showEdit = false
    @State private var confirmDelete = false

    private var sessions: [ReadingSession] {
        book.sessions.sorted { $0.date > $1.date }
    }
    private var projected: Date? { MarginEngine.projectedFinish(for: book) }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                header
                if book.status == .reading || book.status == .dnf || (book.status == .wantToRead && book.currentPage > 0) {
                    progressCard
                }
                ratingCard
                if !book.tags.isEmpty { tagsCard }
                if !book.notes.isEmpty { notesCard }
                sessionsCard
                actions
            }
            .padding(20)
        }
        .background(Brand.pageBackground)
        .navigationTitle(book.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showEdit = true } label: { Label("Edit", systemImage: "pencil") }
            }
        }
        .sheet(isPresented: $showLog) { LogProgressView(book: book) }
        .sheet(isPresented: $showEdit) { BookEditorView(existing: book) }
        .confirmationDialog("Delete this book?",
                            isPresented: $confirmDelete,
                            titleVisibility: .visible) {
            Button("Delete", role: .destructive) { delete() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the book and all its reading sessions. This can't be undone.")
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            BookSpine(book: book, width: 72, height: 104)
            VStack(alignment: .leading, spacing: 8) {
                Text(book.title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Brand.text)
                    .fixedSize(horizontal: false, vertical: true)
                Text(book.author)
                    .font(.subheadline)
                    .foregroundStyle(Brand.text2)
                StatusPill(status: book.status)
                HStack(spacing: 10) {
                    Label(book.genre.label, systemImage: book.genre.symbol)
                    Label(book.format.label, systemImage: book.format.symbol)
                }
                .font(Brand.mono(11))
                .foregroundStyle(Brand.text3)
                Text("\(Format.int(book.totalPages)) pages")
                    .font(Brand.mono(11))
                    .foregroundStyle(Brand.text3)
            }
            Spacer(minLength: 0)
        }
        .glassCard()
    }

    // MARK: Progress

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Progress")
            ProgressBar(fraction: book.progress)
            HStack {
                Text("Page \(book.currentPage) of \(book.totalPages)")
                    .font(Brand.mono(13)).foregroundStyle(Brand.text2)
                Spacer()
                Text(Format.percent(book.progress))
                    .font(Brand.mono(13, weight: .semibold)).foregroundStyle(Brand.magic)
            }
            if let projected, book.status == .reading {
                Label("On pace to finish \(Format.date(projected))", systemImage: "calendar")
                    .font(.footnote).foregroundStyle(Brand.text3)
            }
            if let started = book.startedAt {
                Text("Started \(Format.date(started))")
                    .font(.footnote).foregroundStyle(Brand.text3)
            }
        }
        .glassCard()
    }

    // MARK: Rating

    private var ratingCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: "Your rating")
            StarRating(rating: Binding(
                get: { book.rating },
                set: { book.rating = $0; try? context.save() }
            ))
            if let finished = book.finishedAt {
                Text("Finished \(Format.date(finished))" +
                     (book.daysToFinish.map { " · \($0) day\($0 == 1 ? "" : "s") to read" } ?? ""))
                    .font(.footnote).foregroundStyle(Brand.text3)
            }
        }
        .glassCard()
    }

    // MARK: Tags

    private var tagsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: "Tags")
            FlowLayout(spacing: 8) {
                ForEach(book.tags) { tag in
                    TagChip(text: tag.name, systemImage: "tag", tint: tag.color)
                }
            }
        }
        .glassCard()
    }

    // MARK: Notes

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(text: "Notes")
            Text(book.notes)
                .font(.body)
                .foregroundStyle(Brand.text2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .glassCard()
    }

    // MARK: Sessions

    private var sessionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionTitle(text: "Reading sessions")
                Spacer()
                Text("\(sessions.count)")
                    .font(Brand.mono(13)).foregroundStyle(Brand.text3)
            }
            if sessions.isEmpty {
                Text("No sessions logged yet. Tap Log progress to add one.")
                    .font(.subheadline).foregroundStyle(Brand.text3)
            } else {
                ForEach(sessions) { session in
                    HStack(spacing: 12) {
                        Image(systemName: "book.pages")
                            .font(.system(size: 14))
                            .foregroundStyle(Brand.magic)
                            .frame(width: 24)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(session.pagesRead) page\(session.pagesRead == 1 ? "" : "s")")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Brand.text)
                            if !session.note.isEmpty {
                                Text(session.note).font(.footnote).foregroundStyle(Brand.text2).lineLimit(2)
                            }
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(Format.shortDate(session.date))
                                .font(Brand.mono(12)).foregroundStyle(Brand.text2)
                            if session.minutes > 0 {
                                Text(Format.duration(minutes: session.minutes))
                                    .font(Brand.mono(11)).foregroundStyle(Brand.text3)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    .accessibilityElement(children: .combine)
                    if session.id != sessions.last?.id {
                        Divider().background(Brand.hairline)
                    }
                }
            }
        }
        .glassCard()
    }

    // MARK: Actions

    private var actions: some View {
        VStack(spacing: 12) {
            if book.status != .finished {
                Button { showLog = true } label: {
                    Label("Log progress", systemImage: "plus.circle.fill")
                }
                .buttonStyle(InkButtonStyle())

                Button { markFinished() } label: {
                    Label("Mark finished", systemImage: "checkmark.seal.fill")
                }
                .buttonStyle(GlassButtonStyle())
            } else {
                Button { reopen() } label: {
                    Label("Move back to reading", systemImage: "arrow.uturn.backward")
                }
                .buttonStyle(GlassButtonStyle())
            }

            Button(role: .destructive) { confirmDelete = true } label: {
                Label("Delete book", systemImage: "trash")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .foregroundStyle(Brand.danger)
        }
    }

    // MARK: Mutations

    private func markFinished() {
        book.status = .finished
        book.currentPage = book.totalPages
        if book.startedAt == nil { book.startedAt = .now }
        if book.finishedAt == nil { book.finishedAt = .now }
        try? context.save()
        Haptics.success()
    }

    private func reopen() {
        book.status = .reading
        book.finishedAt = nil
        if book.currentPage >= book.totalPages { book.currentPage = max(0, book.totalPages - 1) }
        try? context.save()
        Haptics.tap()
    }

    private func delete() {
        context.delete(book)
        try? context.save()
        Haptics.warning()
        dismiss()
    }
}
