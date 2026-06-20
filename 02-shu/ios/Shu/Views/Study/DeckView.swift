import SwiftUI
import SwiftData

struct DeckView: View {
    var srsEngine: SRSEngine
    @Environment(\.modelContext) private var modelContext
    @Query private var allReviews: [CardReview]
    @State private var isSessionActive = false
    @AppStorage("sessionSize") private var sessionSize = 10

    private var dueReviews: [CardReview] {
        srsEngine.dueCards(from: allReviews)
    }

    private let columns = [
        GridItem(.adaptive(minimum: 72, maximum: 88), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                ShuTheme.darkNavy.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header card
                        headerCard

                        // Start session button
                        if !dueReviews.isEmpty {
                            Button {
                                isSessionActive = true
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "play.fill")
                                    Text("Start Session (\(min(sessionSize, dueReviews.count)) cards)")
                                }
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundStyle(ShuTheme.darkNavy)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(ShuTheme.gold)
                                .clipShape(RoundedRectangle(cornerRadius: ShuTheme.buttonRadius))
                                .padding(.horizontal, 20)
                            }
                        }

                        // Character grid
                        VStack(alignment: .leading, spacing: 12) {
                            Text("All Characters")
                                .font(ShuTheme.labelFont(size: 13))
                                .foregroundStyle(ShuTheme.subtleText)
                                .padding(.horizontal, 20)

                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(hskWords) { word in
                                    CharacterCell(
                                        word: word,
                                        review: allReviews.first { $0.wordId == word.id },
                                        srsEngine: srsEngine
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("书 Shu")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(ShuTheme.darkNavy, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .fullScreenCover(isPresented: $isSessionActive) {
                SessionView(
                    srsEngine: srsEngine,
                    cards: Array(dueReviews.prefix(sessionSize))
                )
            }
            .task {
                srsEngine.bootstrapReviews(context: modelContext)
            }
        }
    }

    // MARK: - Header Card
    private var headerCard: some View {
        HStack(spacing: 0) {
            statPill(
                value: "\(dueReviews.count)",
                label: "Due Today",
                color: dueReviews.isEmpty ? ShuTheme.correctGreen : ShuTheme.gold
            )
            divider
            statPill(
                value: "\(learnedCount)",
                label: "Learned",
                color: Color(red: 0.35, green: 0.70, blue: 0.96)
            )
            divider
            statPill(
                value: "\(hskWords.count)",
                label: "Total",
                color: ShuTheme.subtleText
            )
        }
        .padding(.vertical, 20)
        .background(ShuTheme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: ShuTheme.cardRadius))
        .padding(.horizontal, 20)
        .shadow(color: ShuTheme.cardShadow, radius: 12, x: 0, y: 4)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(width: 1, height: 44)
    }

    private func statPill(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(ShuTheme.labelFont(size: 12))
                .foregroundStyle(ShuTheme.subtleText)
        }
        .frame(maxWidth: .infinity)
    }

    private var learnedCount: Int {
        allReviews.filter { $0.repetitions > 0 }.count
    }
}

// MARK: - Character Cell
private struct CharacterCell: View {
    let word: HskWord
    let review: CardReview?
    let srsEngine: SRSEngine

    private var mastery: Double {
        guard let r = review else { return 0 }
        return srsEngine.masteryLevel(for: r)
    }

    private var isDue: Bool {
        guard let r = review else { return true }
        return r.dueDate <= .now
    }

    var body: some View {
        ZStack {
            // Mastery fill background
            RoundedRectangle(cornerRadius: ShuTheme.chipRadius)
                .fill(ShuTheme.cardBg)

            RoundedRectangle(cornerRadius: ShuTheme.chipRadius)
                .fill(
                    LinearGradient(
                        colors: [ShuTheme.gold.opacity(0.25 * mastery), .clear],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )

            VStack(spacing: 2) {
                Text(word.character)
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(ShuTheme.primaryText)

                // Mastery dots
                HStack(spacing: 2) {
                    ForEach(0..<5) { i in
                        Circle()
                            .fill(Double(i) / 5.0 < mastery ? ShuTheme.gold : ShuTheme.subtleText.opacity(0.3))
                            .frame(width: 4, height: 4)
                    }
                }
            }
            .padding(8)

            // Due indicator
            if isDue && review?.repetitions != nil {
                Circle()
                    .fill(ShuTheme.gold)
                    .frame(width: 8, height: 8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(6)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

#Preview {
    DeckView(srsEngine: SRSEngine())
        .modelContainer(for: [CardReview.self, StudySession.self], inMemory: true)
}
