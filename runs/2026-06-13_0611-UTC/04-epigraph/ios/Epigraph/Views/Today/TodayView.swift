import SwiftUI
import SwiftData

struct TodayView: View {
    @AppStorage("reviewSize") private var reviewSize = 8
    @Query private var highlights: [Highlight]
    @Query private var books: [Book]
    @State private var showReview = false
    @State private var reviewedTick = false   // forces refresh of streak after review

    private var quoteOfDay: Highlight? { Resurface.ofDay(highlights) }
    private var batchCount: Int { min(reviewSize, highlights.count) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    if let q = quoteOfDay {
                        quoteCard(q)
                        reviewButton
                        statsRow
                    } else {
                        EmptyState(icon: "quote.opening",
                                   title: "Your commonplace book",
                                   message: "Add your first highlight from a book in the Library tab. A daily quote and review will appear here.")
                            .frame(minHeight: 420)
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Today")
            .fullScreenCover(isPresented: $showReview, onDismiss: { reviewedTick.toggle() }) {
                ReviewView(batch: Resurface.batch(highlights, count: batchCount))
            }
        }
    }

    private func quoteCard(_ q: Highlight) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("QUOTE OF THE DAY").font(.system(size: 12, weight: .bold)).tracking(1.2)
                    .foregroundStyle(Theme.accent)
                Spacer()
                Button {
                    q.isFavorite.toggle(); Haptics.tap()
                } label: {
                    Image(systemName: q.isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(q.isFavorite ? Theme.accent : Theme.inkFaint)
                }
                .accessibilityLabel(q.isFavorite ? "Unfavorite" : "Favorite")
            }
            QuoteView(text: q.text, size: 23)
            if let book = q.book {
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 2).fill(Theme.spine(book.spineColor)).frame(width: 4, height: 26)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(book.displayTitle).font(.system(size: 14, weight: .semibold, design: .serif))
                            .foregroundStyle(Theme.ink)
                        if !book.author.isEmpty {
                            Text(book.author).font(.system(size: 12)).foregroundStyle(Theme.inkSoft)
                        }
                    }
                }
            }
            if !q.note.isEmpty {
                Text(q.note).font(.system(size: 14)).italic().foregroundStyle(Theme.inkSoft)
                    .padding(.top, 2)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 22).fill(Theme.surface))
    }

    private var reviewButton: some View {
        Button { showReview = true; Haptics.tap() } label: {
            HStack(spacing: 10) {
                Image(systemName: ReviewStreak.reviewedToday ? "checkmark.circle.fill" : "arrow.triangle.2.circlepath")
                Text(ReviewStreak.reviewedToday ? "Review again" : "Start daily review")
                    .font(.system(size: 17, weight: .semibold))
                Spacer()
                Text("\(batchCount) cards").font(.system(size: 14)).opacity(0.85)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 18).padding(.vertical, 16)
            .background(RoundedRectangle(cornerRadius: 16).fill(Theme.accent))
        }
        .id(reviewedTick)
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            StatTile(value: "\(highlights.count)", label: "Highlights")
            StatTile(value: "\(books.count)", label: "Books")
            StatTile(value: "\(ReviewStreak.current)", label: "Day streak")
        }
        .id(reviewedTick)
    }
}
