import SwiftUI
import SwiftData

/// Home tab. Currently-reading cards with progress + quick log, an up-next strip,
/// a finished-this-year count, and the yearly-challenge ring. Empty state when
/// the library has no books at all.
struct ShelfView: View {
    @Query(sort: \Book.addedAt, order: .reverse) private var books: [Book]
    @AppStorage("margin.goal") private var goal = 24

    @State private var logTarget: Book?

    private var reading: [Book] {
        books.filter { $0.status == .reading }
            .sorted { ($0.startedAt ?? $0.addedAt) > ($1.startedAt ?? $1.addedAt) }
    }
    private var upNext: [Book] {
        books.filter { $0.status == .wantToRead }
            .sorted { $0.addedAt > $1.addedAt }
    }
    private var challenge: MarginEngine.ChallengeProgress {
        MarginEngine.challenge(books, target: goal)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if books.isEmpty {
                    EmptyStateView(icon: "books.vertical",
                                   title: "Your shelf is empty",
                                   message: "Add your first book in the Library tab to start tracking progress and your yearly challenge.")
                        .glassCard()
                        .padding(20)
                } else {
                    VStack(spacing: 18) {
                        challengeCard
                        readingSection
                        if !upNext.isEmpty { upNextSection }
                    }
                    .padding(20)
                }
            }
            .background(Brand.pageBackground)
            .navigationTitle("Shelf")
            .navigationDestination(for: Book.self) { BookDetailView(book: $0) }
        }
        .sheet(item: $logTarget) { LogProgressView(book: $0) }
    }

    // MARK: Challenge card

    private var challengeCard: some View {
        HStack(spacing: 18) {
            ChallengeRing(fraction: challenge.fraction,
                          finished: challenge.finished,
                          target: challenge.target,
                          size: 132)
            VStack(alignment: .leading, spacing: 6) {
                Eyebrow(text: "\(Calendar.current.component(.year, from: .now)) challenge")
                Text(challenge.verdict)
                    .font(.headline)
                    .foregroundStyle(Brand.text)
                    .fixedSize(horizontal: false, vertical: true)
                Text("\(challenge.finished) finished this year")
                    .font(.subheadline)
                    .foregroundStyle(Brand.text2)
                if challenge.target > 0 {
                    Text("Projected \(challenge.projected) by year-end")
                        .font(.footnote)
                        .foregroundStyle(Brand.text3)
                }
            }
            Spacer(minLength: 0)
        }
        .glassCard()
    }

    // MARK: Currently reading

    private var readingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Currently reading")
            if reading.isEmpty {
                Text("Nothing in progress. Start a book from your Up next shelf or Library.")
                    .font(.subheadline)
                    .foregroundStyle(Brand.text2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassCard()
            } else {
                ForEach(reading) { book in
                    ReadingCard(book: book) { logTarget = book }
                }
            }
        }
    }

    // MARK: Up next strip

    private var upNextSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Up next")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(upNext.prefix(12)) { book in
                        NavigationLink(value: book) {
                            VStack(spacing: 8) {
                                BookSpine(book: book, width: 58, height: 84)
                                Text(book.title)
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(Brand.text)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                                    .frame(width: 72)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Up next: \(book.title) by \(book.author)")
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}

/// A currently-reading card: spine, title, progress bar, projected finish, and a
/// quick "Log progress" button.
private struct ReadingCard: View {
    let book: Book
    let onLog: () -> Void

    private var projected: Date? { MarginEngine.projectedFinish(for: book) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            NavigationLink(value: book) {
                HStack(spacing: 14) {
                    BookSpine(book: book)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(book.title)
                            .font(.headline)
                            .foregroundStyle(Brand.text)
                            .lineLimit(2)
                        Text(book.author)
                            .font(.subheadline)
                            .foregroundStyle(Brand.text2)
                            .lineLimit(1)
                        HStack(spacing: 6) {
                            Image(systemName: book.format.symbol)
                                .font(.system(size: 11))
                                .accessibilityHidden(true)
                            Text(book.genre.label)
                                .font(Brand.mono(11))
                        }
                        .foregroundStyle(Brand.text3)
                    }
                    Spacer(minLength: 0)
                }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 6) {
                ProgressBar(fraction: book.progress)
                HStack {
                    Text("Page \(book.currentPage) of \(book.totalPages)")
                        .font(Brand.mono(12))
                        .foregroundStyle(Brand.text2)
                    Spacer()
                    Text(Format.percent(book.progress))
                        .font(Brand.mono(12, weight: .semibold))
                        .foregroundStyle(Brand.magic)
                }
            }

            if let projected {
                Label("On pace to finish \(Format.date(projected))", systemImage: "calendar")
                    .font(.footnote)
                    .foregroundStyle(Brand.text3)
            }

            Button(action: onLog) {
                Label("Log progress", systemImage: "plus.circle.fill")
            }
            .buttonStyle(GlassButtonStyle())
        }
        .glassCard()
    }
}
