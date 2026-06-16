import SwiftUI
import SwiftData

/// To Read: the want-to-read queue, a date-seeded "What next?" picker, reorder & remove.
struct TBRView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Query private var allBooks: [Book]

    @State private var path: [Book] = []
    @State private var showAdd = false
    @State private var paywallReason: PaywallReason?
    @State private var revealedPick: Book?
    @State private var didReveal = false

    private var tbr: [Book] {
        allBooks.filter { $0.shelf == .wantToRead }
            .sorted { $0.dateAdded > $1.dateAdded }
    }

    /// Deterministic daily pick from the TBR queue.
    private var dailyPick: Book? {
        ReadingEngine.dailyPick(from: tbr, seed: ReadingEngine.daySeed())
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Theme.bg.ignoresSafeArea()
                content
            }
            .navigationTitle("To Read")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { addBook() } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add book")
                }
            }
            .navigationDestination(for: Book.self) { BookDetailView(book: $0) }
            .sheet(isPresented: $showAdd) { AddEditBookView(book: nil, defaultShelf: .wantToRead) }
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
        }
    }

    @ViewBuilder
    private var content: some View {
        if tbr.isEmpty {
            EmptyStateView(symbol: "bookmark",
                           title: "Nothing on deck",
                           message: "Add books you want to read next. Tome will help you pick what to start.",
                           actionTitle: "Add a book") { addBook() }
        } else {
            ScrollView {
                VStack(spacing: 18) {
                    whatNextCard
                    queueSection
                }
                .padding(20)
            }
        }
    }

    // MARK: - What next?

    private var whatNextCard: some View {
        VStack(spacing: 14) {
            HStack {
                Label("What should I read next?", systemImage: "wand.and.stars")
                    .font(Theme.serif(18, .semibold))
                    .foregroundStyle(Theme.ink)
                Spacer()
            }
            if didReveal, let pick = revealedPick ?? dailyPick {
                pickReveal(pick)
            } else {
                Text("Let Tome surface one book from your list. A fresh suggestion appears each day.")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                PrimaryButton(title: "Surprise me", systemImage: "sparkles") {
                    reveal()
                }
            }
        }
        .padding(18)
        .cardSurface()
    }

    private func pickReveal(_ book: Book) -> some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                BookCover(title: book.title, author: book.author,
                          colorSeed: book.colorSeed, initials: book.coverInitials,
                          asGradient: settings.showCoversAsGradient)
                    .frame(width: 70)
                VStack(alignment: .leading, spacing: 6) {
                    Text(book.title)
                        .font(Theme.serif(18, .bold))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(3)
                    Text(book.author)
                        .font(Theme.rounded(14))
                        .foregroundStyle(Theme.inkSoft)
                    Text("\(book.pageCount) pages")
                        .font(Theme.rounded(12, .medium))
                        .foregroundStyle(Theme.inkFaint)
                }
                Spacer(minLength: 0)
            }
            HStack(spacing: 10) {
                Button {
                    startReading(book)
                } label: {
                    Label("Start reading", systemImage: "book.fill")
                        .font(Theme.rounded(14, .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .foregroundStyle(.white)
                        .background(RoundedRectangle(cornerRadius: 13, style: .continuous).fill(Theme.heroGradient))
                }
                .buttonStyle(PressableScale())
                Button {
                    reroll()
                } label: {
                    Label("Again", systemImage: "arrow.clockwise")
                        .font(Theme.rounded(14, .semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 11)
                        .foregroundStyle(Theme.accent)
                        .background(RoundedRectangle(cornerRadius: 13, style: .continuous).fill(Theme.accentSoft))
                }
                .buttonStyle(PressableScale())
                .accessibilityLabel("Pick a different book")
            }
        }
    }

    // MARK: - Queue

    private var queueSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Your queue", systemImage: "list.bullet")
            // A List enables native reorder + swipe-to-remove while staying lazy.
            ForEach(tbr) { book in
                queueRow(book)
            }
        }
    }

    private func queueRow(_ book: Book) -> some View {
        HStack(spacing: 12) {
            Button {
                path.append(book)
            } label: {
                HStack(spacing: 12) {
                    BookCover(title: book.title, author: book.author,
                              colorSeed: book.colorSeed, initials: book.coverInitials,
                              asGradient: settings.showCoversAsGradient)
                        .frame(width: 46)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(book.title)
                            .font(Theme.rounded(15, .semibold))
                            .foregroundStyle(Theme.ink)
                            .lineLimit(2)
                        Text(book.author)
                            .font(Theme.rounded(12))
                            .foregroundStyle(Theme.inkSoft)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                }
            }
            .buttonStyle(.plain)

            Menu {
                Button {
                    startReading(book)
                } label: { Label("Start reading", systemImage: "book") }
                Button(role: .destructive) {
                    remove(book)
                } label: { Label("Remove", systemImage: "trash") }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 20))
                    .foregroundStyle(Theme.inkSoft)
            }
            .accessibilityLabel("Options for \(book.title)")
        }
        .padding(12)
        .cardSurface()
    }

    // MARK: - Actions

    private func reveal() {
        revealedPick = dailyPick
        let anim: Animation? = reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.8)
        withAnimation(anim) { didReveal = true }
        Haptics.success(enabled: settings.hapticsEnabled)
    }

    private func reroll() {
        // Pick a different random book from the queue (guards single-item lists).
        let candidates = tbr.filter { $0.id != revealedPick?.id }
        revealedPick = candidates.randomElement() ?? tbr.randomElement()
        Haptics.tap(enabled: settings.hapticsEnabled)
    }

    private func startReading(_ book: Book) {
        book.shelf = .reading
        if book.startedDate == nil { book.startedDate = .now }
        try? context.save()
        Haptics.success(enabled: settings.hapticsEnabled)
        if revealedPick?.id == book.id { didReveal = false; revealedPick = nil }
    }

    private func remove(_ book: Book) {
        context.delete(book)
        try? context.save()
        Haptics.tap(enabled: settings.hapticsEnabled)
        if revealedPick?.id == book.id { didReveal = false; revealedPick = nil }
    }

    private func addBook() {
        if !isPro && allBooks.count >= Pro.freeBookLimit {
            paywallReason = .bookLimit
            Haptics.warning(enabled: settings.hapticsEnabled)
        } else {
            showAdd = true
        }
    }
}
