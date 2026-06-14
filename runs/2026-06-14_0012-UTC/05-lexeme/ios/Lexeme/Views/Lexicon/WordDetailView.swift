import SwiftUI
import SwiftData

/// Pushed detail screen: the full entry, the user's mastery, favorite toggle,
/// and an "add to review" action.
struct WordDetailView: View {
    let word: VocabWord
    @Environment(\.modelContext) private var context
    @State private var refreshToken = 0
    @State private var didAddToReview = false

    private var store: ProgressStore { ProgressStore(context: context) }
    private var progress: WordProgress? { store.existingProgress(for: word.id) }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 18) {
                    LexemeCard {
                        WordEntryView(word: word, showExample: true)
                    }
                    masteryCard
                    actions
                }
                .padding(18)
                .padding(.bottom, 28)
                .id(refreshToken) // recompute derived progress views after a write
            }
        }
        .navigationTitle(word.word)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Haptics.tap()
                    store.toggleFavorite(wordID: word.id)
                    refreshToken += 1
                } label: {
                    Image(systemName: progress?.favorite == true ? "star.fill" : "star")
                        .foregroundStyle(progress?.favorite == true ? Theme.gold : Theme.inkSoft)
                }
                .accessibilityLabel(progress?.favorite == true ? "Remove from favorites" : "Add to favorites")
            }
        }
    }

    private var masteryCard: some View {
        LexemeCard {
            VStack(alignment: .leading, spacing: 14) {
                SectionLabel(text: "Your mastery")
                let p = progress
                let level = p?.level ?? 0
                HStack(spacing: 6) {
                    ForEach(0..<LexemeEngine.maxLevel, id: \.self) { i in
                        Capsule()
                            .fill(i < level ? Theme.accent : Theme.hairline)
                            .frame(height: 8)
                    }
                }
                HStack {
                    masteryLabel(level: level, learned: p?.learned ?? false)
                    Spacer()
                    if let p, p.seen > 0 {
                        Text("\(p.correct)/\(p.seen) correct")
                            .font(Theme.rounded(13, .medium))
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
                if let p, p.seen > 0 {
                    Text("Next review \(p.nextReview.formatted(.relative(presentation: .named)))")
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkFaint)
                } else {
                    Text("Not yet studied. Add it to your review schedule below.")
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkFaint)
                }
            }
        }
    }

    private func masteryLabel(level: Int, learned: Bool) -> some View {
        let title: String
        let color: Color
        if learned { title = "Learned"; color = Theme.good }
        else {
            switch level {
            case 0: title = "New"; color = Theme.inkSoft
            case 1, 2: title = "Learning"; color = Theme.accent
            case 3, 4: title = "Familiar"; color = Theme.teal
            default: title = "Mastered"; color = Theme.good
            }
        }
        return Text(title)
            .font(Theme.rounded(15, .semibold))
            .foregroundStyle(color)
    }

    private var actions: some View {
        VStack(spacing: 10) {
            Button {
                Haptics.success()
                store.addToReview(wordID: word.id)
                withAnimation { didAddToReview = true }
                refreshToken += 1
            } label: {
                Label(didAddToReview ? "Added to review" : "Add to review",
                      systemImage: didAddToReview ? "checkmark.circle.fill" : "plus.circle")
                    .font(Theme.rounded(16, .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(didAddToReview ? Theme.good.opacity(0.15) : Theme.accentSoft,
                                in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .foregroundStyle(didAddToReview ? Theme.good : Theme.accent)
            }
            .buttonStyle(.plain)
            .disabled(didAddToReview)

            if progress?.learned != true {
                Button {
                    Haptics.success()
                    store.markKnown(wordID: word.id)
                    refreshToken += 1
                } label: {
                    Label("Mark as learned", systemImage: "checkmark.seal")
                        .font(Theme.rounded(16, .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.good.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .foregroundStyle(Theme.good)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
