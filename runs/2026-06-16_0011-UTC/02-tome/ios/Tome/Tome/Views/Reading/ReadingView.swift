import SwiftUI
import SwiftData

/// Home: currently reading cards, the reading-challenge ring, recently finished strip.
struct ReadingView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Query private var allBooks: [Book]

    @State private var path: [Book] = []
    @State private var quickLogBook: Book?
    @State private var quickUpdateBook: Book?
    @State private var showAdd = false
    @State private var paywallReason: PaywallReason?

    private var reading: [Book] {
        allBooks.filter { $0.shelf == .reading }
            .sorted { ($0.startedDate ?? .distantPast) > ($1.startedDate ?? .distantPast) }
    }

    private var recentlyFinished: [Book] {
        allBooks.filter { $0.shelf == .finished }
            .sorted { ($0.finishedDate ?? .distantPast) > ($1.finishedDate ?? .distantPast) }
            .prefix(8)
            .map { $0 }
    }

    private var finishedThisYear: Int {
        let year = Calendar.current.component(.year, from: .now)
        return allBooks.filter {
            guard $0.shelf == .finished, let f = $0.finishedDate else { return false }
            return Calendar.current.component(.year, from: f) == year
        }.count
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Theme.bg.ignoresSafeArea()
                content
            }
            .navigationTitle("Reading")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { addBook() } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add book")
                }
            }
            .navigationDestination(for: Book.self) { book in
                BookDetailView(book: book)
            }
            .sheet(isPresented: $showAdd) { AddEditBookView(book: nil, defaultShelf: .reading) }
            .sheet(item: $quickLogBook) { LogSessionView(book: $0) }
            .sheet(item: $quickUpdateBook) { UpdateProgressView(book: $0) }
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
            .task { SeedData.seedIfNeeded(context: context) }
        }
    }

    @ViewBuilder
    private var content: some View {
        if allBooks.isEmpty {
            EmptyStateView(symbol: "book.closed",
                           title: "Start your shelf",
                           message: "Add the book you're reading now, or load a sample library from Settings to explore Tome.",
                           actionTitle: "Add a book") { addBook() }
        } else {
            ScrollView {
                VStack(spacing: 20) {
                    challengeCard
                    currentlyReadingSection
                    if !recentlyFinished.isEmpty { recentlyFinishedSection }
                }
                .padding(20)
            }
        }
    }

    // MARK: - Challenge ring

    private var challengeCard: some View {
        let goal = settings.readingGoal
        let progress = goal > 0 ? min(1, Double(finishedThisYear) / Double(goal)) : 0
        return HStack(spacing: 18) {
            ProgressRing(progress: progress, lineWidth: 11,
                         label: "\(finishedThisYear)/\(goal)")
                .frame(width: 84, height: 84)
            VStack(alignment: .leading, spacing: 6) {
                Text("\(Calendar.current.component(.year, from: .now)) Reading Challenge")
                    .font(Theme.serif(18, .bold))
                    .foregroundStyle(Theme.ink)
                Text(goal > 0
                     ? "\(finishedThisYear) of \(goal) books finished — \(max(0, goal - finishedThisYear)) to go."
                     : "Set a goal in Settings to track your year.")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .cardSurface()
        .accessibilityElement(children: .combine)
    }

    // MARK: - Currently reading

    private var currentlyReadingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Currently Reading", systemImage: "book")
            if reading.isEmpty {
                emptyMini("Nothing in progress. Move a book to “Reading” to see it here.",
                          symbol: "book")
            } else {
                ForEach(reading) { book in
                    currentCard(book)
                }
            }
        }
    }

    private func currentCard(_ book: Book) -> some View {
        Button {
            path.append(book)
        } label: {
            HStack(spacing: 14) {
                BookCover(title: book.title, author: book.author,
                          colorSeed: book.colorSeed, initials: book.coverInitials,
                          asGradient: settings.showCoversAsGradient)
                    .frame(width: 60)
                VStack(alignment: .leading, spacing: 8) {
                    Text(book.title)
                        .font(Theme.serif(17, .semibold))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(2)
                    Text(book.author)
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkSoft)
                        .lineLimit(1)
                    ProgressView(value: book.progress).tint(Theme.accent)
                    Text("Page \(book.currentPage) of \(book.pageCount) · \(Int(book.progress * 100))%")
                        .font(Theme.rounded(12, .medium))
                        .foregroundStyle(Theme.inkFaint)
                        .monospacedDigit()
                    HStack(spacing: 8) {
                        miniAction("Update", "slider.horizontal.3") { quickUpdateBook = book }
                        miniAction("Log", "plus") { quickLogBook = book }
                    }
                    .padding(.top, 2)
                }
            }
            .padding(14)
            .cardSurface()
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens book details")
    }

    private func miniAction(_ title: String, _ symbol: String, action: @escaping () -> Void) -> some View {
        Button {
            action()
            Haptics.tap(enabled: settings.hapticsEnabled)
        } label: {
            Label(title, systemImage: symbol)
                .font(Theme.rounded(12, .semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(Theme.accentSoft))
                .foregroundStyle(Theme.accent)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Recently finished

    private var recentlyFinishedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Recently Finished", systemImage: "checkmark.seal")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(recentlyFinished) { book in
                        Button {
                            path.append(book)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                BookCover(title: book.title, author: book.author,
                                          colorSeed: book.colorSeed, initials: book.coverInitials,
                                          asGradient: settings.showCoversAsGradient)
                                    .frame(width: 86)
                                if let rating = book.rating, rating > 0 {
                                    StarRow(rating: rating, size: 10)
                                }
                            }
                            .frame(width: 86)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }

    private func emptyMini(_ text: String, symbol: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: symbol).foregroundStyle(Theme.inkFaint)
            Text(text).font(Theme.rounded(14)).foregroundStyle(Theme.inkSoft)
            Spacer()
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.surfaceAlt))
    }

    // MARK: - Add gating

    private func addBook() {
        if !isPro && allBooks.count >= Pro.freeBookLimit {
            paywallReason = .bookLimit
            Haptics.warning(enabled: settings.hapticsEnabled)
        } else {
            showAdd = true
        }
    }
}
